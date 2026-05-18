import Foundation

/// Версия формата `.synapps` файла. Bump при breaking changes в схеме.
enum SynappsBundleVersion {
  static let current = 1
}

struct SynappsBundle {
  let version: Int
  let type: BundleType
  let exportedAt: Date
  let payload: Payload

  enum BundleType: String, Codable {
    case mindmap
    case collection
    case card
  }

  enum Payload {
    case mindmap(MindMapPayload)
    case collection(CollectionPayload)
    case card(CardDTO)
  }
}

// MARK: - Payload types

struct MindMapPayload: Codable {
  let title: String
  let bookId: String?
  let cards: [CardDTO]
}

struct CollectionPayload: Codable {
  let collection: CollectionDTO
  let cards: [CardDTO]
}

struct CollectionDTO: Codable {
  let id: String
  let title: String
  let cardIds: [String]
}

struct CardDTO: Codable {
  let id: String
  let type: CardType
  let content: String
  let references: References
  let tags: [Tag]
  let bookId: String?
  let savedAt: Date?
}

extension CardDTO {
  init(card: Card) {
    self.init(
      id: card.id,
      type: card.type,
      content: card.content,
      references: card.references,
      tags: card.tags,
      bookId: card.bookId,
      savedAt: card.savedAt
    )
  }

  /// Преобразование в @Model для импорта. `overrideId` / `overrideBookId` позволяют
  /// импортёру перегенерировать id и сбросить bookId согласно правилам импорта.
  func toModel(overrideId: String? = nil, overrideBookId: String?? = nil, savedAt: Date? = .now) -> Card {
    Card(
      id: overrideId ?? id,
      type: type,
      content: content,
      references: references,
      tags: tags,
      bookId: overrideBookId ?? bookId,
      savedAt: savedAt
    )
  }
}

// MARK: - SynappsBundle Codable

extension SynappsBundle: Codable {
  enum CodingKeys: String, CodingKey {
    case version, type, exportedAt, payload
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let version = try container.decode(Int.self, forKey: .version)
    let type = try container.decode(BundleType.self, forKey: .type)
    let exportedAt = try container.decode(Date.self, forKey: .exportedAt)

    let payload: Payload
    switch type {
    case .mindmap:
      payload = .mindmap(try container.decode(MindMapPayload.self, forKey: .payload))
    case .collection:
      payload = .collection(try container.decode(CollectionPayload.self, forKey: .payload))
    case .card:
      payload = .card(try container.decode(CardDTO.self, forKey: .payload))
    }

    self.init(version: version, type: type, exportedAt: exportedAt, payload: payload)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(version, forKey: .version)
    try container.encode(type, forKey: .type)
    try container.encode(exportedAt, forKey: .exportedAt)
    switch payload {
    case .mindmap(let p):    try container.encode(p, forKey: .payload)
    case .collection(let p): try container.encode(p, forKey: .payload)
    case .card(let p):       try container.encode(p, forKey: .payload)
    }
  }
}

// MARK: - Shared coders

enum SynappsBundleCoder {
  static func encoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }

  static func decoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
