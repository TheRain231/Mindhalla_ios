import Foundation
import SwiftData

enum SynappsBundleImporter {
  struct ImportResult {
    let type: SynappsBundle.BundleType
    let insertedCardCount: Int
    let insertedCollectionId: String?
    let droppedBookIdCount: Int
  }

  enum ImportError: LocalizedError, Identifiable {
    case unreadable
    case notSynappsBundle
    case unsupportedVersion(Int)

    var id: String {
      switch self {
      case .unreadable: "unreadable"
      case .notSynappsBundle: "notSynappsBundle"
      case .unsupportedVersion(let v): "unsupportedVersion-\(v)"
      }
    }

    var errorDescription: String? {
      switch self {
      case .unreadable:
        String(localized: "Import.Error.Unreadable")
      case .notSynappsBundle:
        String(localized: "Import.Error.NotSynappsBundle")
      case .unsupportedVersion(let version):
        String(format: String(localized: "Import.Error.UnsupportedVersion"), version)
      }
    }
  }

  @MainActor
  static func performImport(from url: URL, modelContext: ModelContext) throws -> ImportResult {
    let didStartAccess = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccess { url.stopAccessingSecurityScopedResource() }
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw ImportError.unreadable
    }

    let bundle: SynappsBundle
    do {
      bundle = try SynappsBundleCoder.decoder().decode(SynappsBundle.self, from: data)
    } catch {
      throw ImportError.notSynappsBundle
    }

    guard bundle.version <= SynappsBundleVersion.current else {
      throw ImportError.unsupportedVersion(bundle.version)
    }

    switch bundle.payload {
    case .card(let dto):
      return importCard(dto: dto, in: modelContext)
    case .collection(let payload):
      return importCollection(payload: payload, in: modelContext)
    case .mindmap(let payload):
      return importMindMap(payload: payload, in: modelContext)
    }
  }

  // MARK: - Per-type import

  @MainActor
  private static func importCard(dto: CardDTO, in context: ModelContext) -> ImportResult {
    let newId = UUID().uuidString
    let bookIdResolved = resolveBookId(dto.bookId, in: context)
    let card = dto.toModel(overrideId: newId, overrideBookId: .some(bookIdResolved))
    context.insert(card)
    try? context.save()

    return ImportResult(
      type: .card,
      insertedCardCount: 1,
      insertedCollectionId: nil,
      droppedBookIdCount: (dto.bookId != nil && bookIdResolved == nil) ? 1 : 0
    )
  }

  @MainActor
  private static func importCollection(payload: CollectionPayload, in context: ModelContext) -> ImportResult {
    let idMap = makeIdMap(for: payload.cards)
    var dropped = 0
    let newCards = payload.cards.map { dto -> Card in
      let resolvedBookId = resolveBookId(dto.bookId, in: context)
      if dto.bookId != nil, resolvedBookId == nil { dropped += 1 }
      return dto.toModel(overrideId: idMap[dto.id]!, overrideBookId: .some(resolvedBookId))
    }
    newCards.forEach { context.insert($0) }

    let newCollectionId = UUID().uuidString
    let remappedCardIds = payload.collection.cardIds.map { idMap[$0] ?? $0 }
    let collection = QuoteCollection(
      id: newCollectionId,
      title: payload.collection.title,
      cardIds: remappedCardIds
    )
    context.insert(collection)
    try? context.save()

    return ImportResult(
      type: .collection,
      insertedCardCount: newCards.count,
      insertedCollectionId: newCollectionId,
      droppedBookIdCount: dropped
    )
  }

  @MainActor
  private static func importMindMap(payload: MindMapPayload, in context: ModelContext) -> ImportResult {
    let idMap = makeIdMap(for: payload.cards)
    var dropped = 0
    let newCards = payload.cards.map { dto -> Card in
      let resolvedBookId = resolveBookId(dto.bookId, in: context)
      if dto.bookId != nil, resolvedBookId == nil { dropped += 1 }
      return dto.toModel(overrideId: idMap[dto.id]!, overrideBookId: .some(resolvedBookId))
    }
    newCards.forEach { context.insert($0) }
    try? context.save()

    return ImportResult(
      type: .mindmap,
      insertedCardCount: newCards.count,
      insertedCollectionId: nil,
      droppedBookIdCount: dropped
    )
  }

  // MARK: - Helpers

  private static func makeIdMap(for cards: [CardDTO]) -> [String: String] {
    Dictionary(uniqueKeysWithValues: cards.map { ($0.id, UUID().uuidString) })
  }

  /// Возвращает bookId только если у получателя реально есть такая книга в SwiftData,
  /// иначе nil — карточка импортируется без привязки. Refs (originalTexts, pages) остаются.
  @MainActor
  private static func resolveBookId(_ bookId: String?, in context: ModelContext) -> String? {
    guard let bookId else { return nil }
    let descriptor = FetchDescriptor<BookMetaResponse>(predicate: #Predicate { $0.id == bookId })
    let exists = ((try? context.fetch(descriptor))?.isEmpty == false)
    return exists ? bookId : nil
  }
}
