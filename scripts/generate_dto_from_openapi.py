#!/usr/bin/env python3
"""
Генерирует Synapps/Models/DTO.swift из openapi.json (OpenAPI 3.x).

Запуск из корня репозитория:
  python3 scripts/generate_dto_from_openapi.py
  python3 scripts/generate_dto_from_openapi.py --openapi path/to/openapi.json --output Synapps/Models/DTO.swift
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict, deque
from pathlib import Path
from typing import Any


def snake_to_camel(name: str) -> str:
    parts = name.split("_")
    head = parts[0].lower()
    tail = "".join(p[:1].upper() + p[1:] if p else "" for p in parts[1:])
    return head + tail


def ref_to_schema_name(ref: str) -> str:
    # "#/components/schemas/BookMetaResponse" -> BookMetaResponse
    return ref.rsplit("/", 1)[-1]


def is_null_schema(s: dict[str, Any]) -> bool:
    return s.get("type") == "null"


class TypeExpr:
    __slots__ = ("swift", "optional")

    def __init__(self, swift: str, optional: bool = False) -> None:
        self.swift = swift
        self.optional = optional


def merge_optional(a: TypeExpr, b: bool) -> TypeExpr:
    return TypeExpr(a.swift, a.optional or b)


class OpenAPIToSwift:
    def __init__(self, schemas: dict[str, Any]) -> None:
        self.schemas = schemas

    def resolve_schema_type(self, schema: dict[str, Any], in_optional_union: bool = False) -> TypeExpr:
        if not schema:
            return TypeExpr("AnyCodable", True)

        if "$ref" in schema:
            name = ref_to_schema_name(schema["$ref"])
            return TypeExpr(f"{name}DTO", False)

        if "anyOf" in schema:
            return self._resolve_any_of(schema["anyOf"], in_optional_union)

        if "allOf" in schema:
            # минимальная поддержка: взять первый не-примитив или первый ref
            for part in schema["allOf"]:
                if isinstance(part, dict) and part:
                    return self.resolve_schema_type(part, in_optional_union)
            return TypeExpr("AnyCodable", True)

        t = schema.get("type")

        if t == "object":
            addl = schema.get("additionalProperties")
            if addl is True:
                return TypeExpr("[String: AnyCodable]", False)
            if isinstance(addl, dict):
                inner = self.resolve_schema_type(addl, True)
                return TypeExpr(f"[String: {inner.swift}]", inner.optional)
            props = schema.get("properties") or {}
            if not props and not schema.get("properties"):
                return TypeExpr("[String: AnyCodable]", False)
            return TypeExpr("AnyCodable", True)

        if t == "array":
            items = schema.get("items") or {}
            inner = self.resolve_schema_type(items, False)
            return TypeExpr(f"[{inner.swift}]", inner.optional)

        if t == "string":
            fmt = schema.get("format")
            if fmt == "binary":
                return TypeExpr("Data", False)
            return TypeExpr("String", False)

        if t == "integer":
            return TypeExpr("Int", False)

        if t == "number":
            return TypeExpr("Double", False)

        if t == "boolean":
            return TypeExpr("Bool", False)

        return TypeExpr("AnyCodable", True)

    def _resolve_any_of(self, variants: list[dict[str, Any]], in_optional_union: bool) -> TypeExpr:
        non_null = [v for v in variants if isinstance(v, dict) and not is_null_schema(v)]
        has_null = any(is_null_schema(v) for v in variants if isinstance(v, dict))

        if len(non_null) == 1:
            inner = self.resolve_schema_type(non_null[0], False)
            return merge_optional(inner, has_null or in_optional_union)

        # несколько ненулевых типов — обобщаем
        if len(non_null) == 0:
            return TypeExpr("AnyCodable?", True)

        primitive_kinds: set[str] = set()
        for v in non_null:
            if "$ref" in v:
                return TypeExpr("AnyCodable", has_null or in_optional_union)
            vt = v.get("type")
            if vt == "string":
                primitive_kinds.add("string")
            elif vt == "integer":
                primitive_kinds.add("integer")
            elif vt == "number":
                primitive_kinds.add("number")
            elif vt == "boolean":
                primitive_kinds.add("boolean")
            else:
                return TypeExpr("AnyCodable", has_null or in_optional_union)

        if primitive_kinds <= {"string", "integer"} or primitive_kinds <= {"string"}:
            # loc: string | int
            return TypeExpr("AnyCodable", has_null or in_optional_union)

        return TypeExpr("AnyCodable", has_null or in_optional_union)

    def property_type(
        self,
        json_key: str,
        prop_schema: dict[str, Any],
        required: bool,
    ) -> TypeExpr:
        t = self.resolve_schema_type(prop_schema, False)
        optional = (not required) or t.optional
        swift_t = t.swift
        if optional and not swift_t.endswith("?"):
            # AnyCodable уже может быть с ?
            if swift_t == "AnyCodable":
                swift_t = "AnyCodable?"
            else:
                swift_t = f"{swift_t}?"
        elif not optional and swift_t.endswith("?"):
            swift_t = swift_t.rstrip("?")
        return TypeExpr(f"  let {snake_to_camel(json_key)}: {swift_t}", False)


def collect_refs_from_schema(schema: dict[str, Any], out: set[str]) -> None:
    if not isinstance(schema, dict):
        return
    if "$ref" in schema:
        out.add(ref_to_schema_name(schema["$ref"]))
        return
    for k, v in schema.items():
        if k == "description":
            continue
        if isinstance(v, dict):
            collect_refs_from_schema(v, out)
        elif isinstance(v, list):
            for item in v:
                if isinstance(item, dict):
                    collect_refs_from_schema(item, out)


def topological_order(schemas: dict[str, Any], names: list[str]) -> list[str]:
    """Порядок: сначала зависимости, затем зависящие (как в исходном DTO — вложенные типы можно ниже)."""
    graph: dict[str, set[str]] = defaultdict(set)
    for name in names:
        sch = schemas.get(name) or {}
        deps: set[str] = set()
        collect_refs_from_schema(sch, deps)
        deps &= set(names)
        deps.discard(name)
        graph[name] = deps

    indeg = {n: 0 for n in names}
    for n in names:
        for d in graph[n]:
            indeg[n] += 1

    # Kahn: хотим чтобы зависимости шли раньше — считаем reverse: кто от кого зависит
    rev: dict[str, set[str]] = defaultdict(set)
    for n, deps in graph.items():
        for d in deps:
            rev[d].add(n)

    queue = deque([n for n in names if indeg[n] == 0])
    result: list[str] = []
    remaining = set(names)

    while queue:
        n = queue.popleft()
        result.append(n)
        for m in rev.get(n, ()):
            indeg[m] -= 1
            if indeg[m] == 0:
                queue.append(m)
        remaining.discard(n)

    if len(result) != len(names):
        # цикл или ошибка — стабильный fallback
        return sorted(names)

    return result


def escape_swift_doc(s: str) -> str:
    return s.replace("*/", "*\\/")


def format_description(desc: str | None, indent: str = "") -> str:
    if not desc:
        return ""
    desc = desc.replace("`None`", "`nil`").replace(" None ", " nil ")
    lines = [ln.rstrip() for ln in desc.strip().splitlines()]
    if not lines:
        return ""
    out = [f"{indent}/// {escape_swift_doc(lines[0])}"]
    for ln in lines[1:]:
        out.append(f"{indent}/// {escape_swift_doc(ln)}")
    return "\n".join(out) + "\n"


def needs_coding_keys(json_key: str, swift_prop: str) -> bool:
    return json_key != swift_prop


def generate_struct(
    name: str,
    schema: dict[str, Any],
    converter: OpenAPIToSwift,
) -> str:
    props = schema.get("properties") or {}
    required_set = set(schema.get("required") or []) | EXTRA_REQUIRED_FIELDS.get(name, set())

    lines: list[str] = []
    desc = schema.get("description")
    desc_block = format_description(desc)
    if desc_block:
        lines.append(desc_block.rstrip())

    lines.append(f"struct {name}DTO: Codable {{")

    coding_pairs: list[tuple[str, str]] = []

    for json_key in props.keys():
        swift_prop = snake_to_camel(json_key)
        prop_schema = props[json_key]
        is_req = json_key in required_set

        if name == "UploadRequest" and json_key == "files":
            max_items = prop_schema.get("maxItems")
            if max_items:
                lines.append(f"  /// Max {max_items} files")
            lines.append("  let files: [Data]")
            continue

        texpr = converter.property_type(json_key, prop_schema, is_req)
        lines.append(texpr.swift.rstrip())
        coding_pairs.append((swift_prop, json_key))

    needs_enum = any(needs_coding_keys(jk, snake_to_camel(jk)) for jk in props.keys())
    if needs_enum and props:
        lines.append("")
        lines.append("  enum CodingKeys: String, CodingKey {")
        for swift_prop, json_key in coding_pairs:
            if swift_prop == json_key:
                lines.append(f"    case {swift_prop}")
            else:
                lines.append(f'    case {swift_prop} = "{json_key}"')
        lines.append("  }")

    lines.append("}")
    return "\n".join(lines)


# Поля, обязательные в Swift, если в спецификации не отмечены как required (например, сервер всегда шлёт массив).
EXTRA_REQUIRED_FIELDS: dict[str, set[str]] = {
    "BookMetaResponse": {"authors", "genres"},
}

DEFAULT_MARK_SECTIONS: list[tuple[str, list[str]]] = [
    ("Upload", ["UploadRequest", "UploadResponse", "UploadFileInfoResponse"]),
    ("Books List", ["BooksMetaResponse", "PaginationMeta", "BookMetaResponse"]),
    ("Book By ID", ["BookByIdResponse"]),
    ("Book Card", ["BookCardResponse", "BookCardTagResponse"]),
    ("Shared", ["BookAuthorResponse", "BookGenreResponse"]),
    ("Validation Error", ["HTTPValidationError", "ValidationError"]),
]


def flatten_mark_order(sections: list[tuple[str, list[str]]]) -> list[str]:
    out: list[str] = []
    for _, names in sections:
        out.extend(names)
    return out


def run(openapi_path: Path, output_path: Path, mark_sections: list[tuple[str, list[str]]]) -> None:
    data = json.loads(openapi_path.read_text(encoding="utf-8"))
    schemas = (data.get("components") or {}).get("schemas") or {}
    if not schemas:
        print("В openapi нет components.schemas", file=sys.stderr)
        sys.exit(1)

    converter = OpenAPIToSwift(schemas)

    mark_order_set = set(flatten_mark_order(mark_sections))
    other = [n for n in sorted(schemas.keys()) if n not in mark_order_set]

    ordered_for_topo = list(dict.fromkeys(flatten_mark_order(mark_sections) + other))
    ordered_for_topo = [n for n in ordered_for_topo if n in schemas]
    topo_names = topological_order(schemas, ordered_for_topo)

    # порядок вывода: как в MARK, внутри секции — порядок из topo_names
    topo_rank = {n: i for i, n in enumerate(topo_names)}

    sections_out: list[tuple[str, list[str]]] = list(mark_sections)
    if other:
        sections_out.append(("Other", sorted(other)))

    generated_blocks: list[str] = []
    seen: set[str] = set()

    for title, names in sections_out:
        block_names = [n for n in names if n in schemas]
        if not block_names:
            continue
        order_in_section = {n: i for i, n in enumerate(names)}
        if title == "Other":
            sorted_block = sorted(block_names, key=lambda n: topo_rank.get(n, 10**9))
        else:
            sorted_block = sorted(block_names, key=lambda n: order_in_section.get(n, 999))
        structs: list[str] = []
        for schema_name in sorted_block:
            if schema_name in seen:
                continue
            seen.add(schema_name)
            sch = schemas[schema_name]
            if (sch or {}).get("type") != "object" and "properties" not in (sch or {}):
                continue
            structs.append(generate_struct(schema_name, sch, converter))
        if structs:
            generated_blocks.append(f"// MARK: - {title}\n\n" + "\n\n".join(structs))

    header = """//
//  DTO.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import AnyCodable
import Foundation
"""

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(header + "\n" + "\n\n".join(generated_blocks) + "\n", encoding="utf-8")
    print(f"Written: {output_path}")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    p = argparse.ArgumentParser(description="Генерация DTO.swift из OpenAPI JSON")
    p.add_argument(
        "--openapi",
        type=Path,
        default=root / "openapi.json",
        help="Путь к openapi.json",
    )
    p.add_argument(
        "--output",
        type=Path,
        default=root / "Synapps" / "Models" / "DTO.swift",
        help="Куда записать DTO.swift",
    )
    args = p.parse_args()
    run(args.openapi.resolve(), args.output.resolve(), DEFAULT_MARK_SECTIONS)


if __name__ == "__main__":
    main()
