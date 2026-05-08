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
    print("[AutoTag v3] runFullPass start (stopwords expanded, no 3-grams, participle filter)")
    let descriptor = FetchDescriptor<Card>()
    let cards = (try? modelContext.fetch(descriptor)) ?? []
    print("[AutoTag] fetched \(cards.count) cards")
    guard cards.count >= 2 else {
      print("[AutoTag] not enough cards, skipping")
      return
    }

    let clusters: [[Card]]
    do {
      clusters = try await clusteringService.cluster(cards: cards)
      print("[AutoTag] clustered into \(clusters.count) groups: \(clusters.map(\.count))")
    } catch {
      print("[AutoTag] clustering failed: \(error)")
      throw error
    }

    for card in cards {
      card.tags.removeAll { $0.type == Self.autoTagType }
    }

    let topics = TopicExtractor.extractTopics(for: clusters.map { $0.map(\.content) })

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
