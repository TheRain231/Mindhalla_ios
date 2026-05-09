import Foundation
import SwiftUI

enum MindMapPalette {
  static let primary = Color(hex: "8B5CF6")
  static let secondary = Color(hex: "B79CF1")
}

struct MindMapNode: Identifiable, Hashable {
  enum Kind { case root, subtopic, card }
  let id: String
  let kind: Kind
  let title: String
  let card: Card?

  static func == (lhs: MindMapNode, rhs: MindMapNode) -> Bool { lhs.id == rhs.id }
  func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct MindMapEdge: Identifiable, Hashable {
  let id: String
  let from: String
  let to: String
}

struct MindMap: Identifiable, Hashable {
  let id: String
  let title: String
  let nodes: [MindMapNode]
  let edges: [MindMapEdge]
  let cardCount: Int
  let bookId: String?

  static func == (lhs: MindMap, rhs: MindMap) -> Bool { lhs.id == rhs.id }
  func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@MainActor
final class MindMapBuilder {
  static let subTopicThreshold: Float = 0.66
  static let minRootClusterSize = 3

  private let clusteringService: CardClusteringService

  init(clusteringService: CardClusteringService) {
    self.clusteringService = clusteringService
  }

  func build(from cards: [Card]) async throws -> [MindMap] {
    var byTag: [String: (name: String, cards: [Card])] = [:]
    for card in cards {
      guard let tag = card.tags.first(where: { $0.type == AutoTaggingService.autoTagType }) else { continue }
      var entry = byTag[tag.id] ?? (name: tag.name, cards: [])
      entry.cards.append(card)
      byTag[tag.id] = entry
    }

    var maps: [MindMap] = []
    for (tagId, entry) in byTag where entry.cards.count >= Self.minRootClusterSize {
      let map = try await buildOne(rootId: tagId, rootTitle: entry.name, cards: entry.cards)
      maps.append(map)
    }
    return maps.sorted { $0.cardCount > $1.cardCount }
  }

  private func buildOne(rootId: String, rootTitle: String, cards: [Card]) async throws -> MindMap {
    let result = try await clusteringService.cluster(cards: cards, threshold: Self.subTopicThreshold)
    let subClusters = result.clusters

    let multi = subClusters.enumerated().filter { $0.element.count >= 2 }
    let singletons = subClusters.filter { $0.count < 2 }.flatMap { $0 }

    let texts = multi.map { $0.element.map(\.content) }
    let vectors = multi.map { $0.element.compactMap { result.vectorsById[$0.id] } }
    let embedder = clusteringService.embeddingService
    let topics: [String?]
    if texts.isEmpty {
      topics = []
    } else {
      do {
        let rootVecBatch = try await embedder.embed(batch: [rootTitle])
        let anchors = rootVecBatch.isEmpty ? [] : [rootVecBatch[0]]
        topics = try await TopicExtractor.extractTopicsSemantic(
          clusters: texts,
          clusterVectors: vectors,
          excludedPhrases: [rootTitle],
          diversityAnchorVectors: anchors,
          diversityWeight: 0.5,
          embed: { try await embedder.embed(batch: $0) }
        )
      } catch {
        topics = TopicExtractor.extractTopics(for: texts)
      }
    }

    let rootNodeId = "root-\(rootId)"
    var nodes: [MindMapNode] = [MindMapNode(id: rootNodeId, kind: .root, title: rootTitle, card: nil)]
    var edges: [MindMapEdge] = []
    let rootLower = rootTitle.lowercased()

    print("[MindMaps] root=\"\(rootTitle)\" subtopics=\(topics.compactMap { $0 })")

    for (idx, pair) in multi.enumerated() {
      let topic = topics.indices.contains(idx) ? topics[idx] : nil
      let cleaned: String? = (topic?.lowercased() == rootLower) ? nil : topic
      let subtitle = cleaned?.isEmpty == false ? cleaned! : "Подгруппа \(idx + 1)"
      let subId = "sub-\(rootId)-\(idx)"
      nodes.append(MindMapNode(id: subId, kind: .subtopic, title: subtitle, card: nil))
      edges.append(MindMapEdge(id: "e-\(rootNodeId)-\(subId)", from: rootNodeId, to: subId))
      for card in pair.element {
        let cardNodeId = "card-\(card.id)"
        nodes.append(MindMapNode(id: cardNodeId, kind: .card, title: card.content, card: card))
        edges.append(MindMapEdge(id: "e-\(subId)-\(cardNodeId)", from: subId, to: cardNodeId))
      }
    }

    for card in singletons {
      let cardNodeId = "card-\(card.id)"
      nodes.append(MindMapNode(id: cardNodeId, kind: .card, title: card.content, card: card))
      edges.append(MindMapEdge(id: "e-\(rootNodeId)-\(cardNodeId)", from: rootNodeId, to: cardNodeId))
    }

    let dominantBook = Self.dominantBook(in: cards)
    return MindMap(id: rootId, title: rootTitle, nodes: nodes, edges: edges, cardCount: cards.count, bookId: dominantBook)
  }

  private static func dominantBook(in cards: [Card]) -> String? {
    var counts: [String: Int] = [:]
    for card in cards {
      guard let id = card.bookId else { continue }
      counts[id, default: 0] += 1
    }
    return counts.max { $0.value < $1.value }?.key
  }
}
