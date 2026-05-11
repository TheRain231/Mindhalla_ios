import Foundation
import SwiftData
import WidgetKit

@MainActor
final class AutoTaggingService {
  static let autoTagType = "auto"

  private let modelContext: ModelContext
  private let clusteringService: CardClusteringService

  init(modelContext: ModelContext, clusteringService: CardClusteringService) {
    self.modelContext = modelContext
    self.clusteringService = clusteringService
  }

  func runFullPass() async throws {
    print("[AutoTag v6] runFullPass start (mean-link clustering + KeyBERT-style topics)")
    let descriptor = FetchDescriptor<Card>()
    let cards = (try? modelContext.fetch(descriptor)) ?? []
    print("[AutoTag] fetched \(cards.count) cards")
    guard cards.count >= 2 else {
      print("[AutoTag] not enough cards, skipping")
      return
    }

    let result: CardClusteringService.Result
    do {
      result = try await clusteringService.cluster(cards: cards)
      print("[AutoTag] clustered into \(result.clusters.count) groups: \(result.clusters.map(\.count))")
    } catch {
      print("[AutoTag] clustering failed: \(error)")
      throw error
    }
    let clusters = result.clusters

    for card in cards {
      card.tags.removeAll { $0.type == Self.autoTagType }
    }

    let clusterTexts = clusters.map { $0.map(\.content) }
    let clusterVectors = clusters.map { $0.compactMap { result.vectorsById[$0.id] } }
    let embedder = clusteringService.embeddingService
    let topics: [String?]
    do {
      topics = try await TopicExtractor.extractTopicsSemantic(
        clusters: clusterTexts,
        clusterVectors: clusterVectors,
        embed: { try await embedder.embed(batch: $0) }
      )
    } catch {
      print("[AutoTag] semantic topics failed: \(error)")
      topics = Array(repeating: nil, count: clusterTexts.count)
    }

    var assigned = 0
    for (cluster, topic) in zip(clusters, topics) where cluster.count >= 2 {
      print("[AutoTag] cluster size=\(cluster.count) topic=\(topic ?? "nil")")
      guard let topic, !topic.isEmpty else { continue }
      let tag = Tag(
        id: "auto-\(slug(topic))",
        type: Self.autoTagType,
        name: topic,
        description: ""
      )
      for card in cluster {
        card.tags.append(tag)
      }
      assigned += 1
    }
    print("[AutoTag] tagged \(assigned) clusters")

    try? modelContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func slug(_ s: String) -> String {
    let lower = s.lowercased()
    let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789-абвгдеёжзийклмнопрстуфхцчшщъыьэюя")
    let mapped = lower.map { ch -> Character in
      if ch == " " { return "-" }
      return allowed.contains(ch) ? ch : "-"
    }
    return String(mapped)
  }
}
