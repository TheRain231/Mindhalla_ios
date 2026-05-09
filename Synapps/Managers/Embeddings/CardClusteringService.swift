import Foundation
import SwiftData
import WidgetKit

/// Greedy single-link clustering of cards by cosine similarity of their content embeddings.
/// Embeddings are cached in `CardEmbedding` keyed by `cardId` + `modelVersion`.
@MainActor
final class CardClusteringService {
  static let defaultThreshold: Float = 0.6

  private let modelContext: ModelContext
  private let embeddingService: EmbeddingService

  init(modelContext: ModelContext, embeddingService: EmbeddingService) {
    self.modelContext = modelContext
    self.embeddingService = embeddingService
  }

  /// Returns groups of cards. Order within each group reflects input order.
  /// `threshold` is the minimum cosine similarity required to merge into an existing cluster.
  func cluster(cards: [Card], threshold: Float = CardClusteringService.defaultThreshold) async throws -> [[Card]] {
    guard !cards.isEmpty else { return [] }

    let vectors = try await embedAll(cards: cards)

    var clusters: [[Int]] = []
    for i in 0..<cards.count {
      let v = vectors[i]
      var bestCluster = -1
      var bestScore: Float = threshold
      for (idx, cluster) in clusters.enumerated() {
        for member in cluster {
          let score = CosineSimilarity.cosine(v, vectors[member])
          if score >= bestScore {
            bestScore = score
            bestCluster = idx
            break
          }
        }
      }
      if bestCluster >= 0 {
        clusters[bestCluster].append(i)
      } else {
        clusters.append([i])
      }
    }

    return clusters.map { idxs in idxs.map { cards[$0] } }
  }

  /// Computes (or fetches from cache) embeddings for the given cards. Persists newly computed ones.
  private func embedAll(cards: [Card]) async throws -> [[Float]] {
    let version = embeddingService.modelVersion
    let cardIds = cards.map(\.id)

    let cached = fetchCached(ids: cardIds, version: version)
    var byId = Dictionary(uniqueKeysWithValues: cached.map { ($0.cardId, $0) })

    var missing: [(index: Int, card: Card)] = []
    var result: [[Float]] = Array(repeating: [], count: cards.count)
    for (i, card) in cards.enumerated() {
      if let entry = byId[card.id] {
        result[i] = entry.floats
      } else {
        missing.append((i, card))
      }
    }

    if !missing.isEmpty {
      let texts = missing.map { $0.card.content }
      let computed = try await embeddingService.embed(batch: texts)
      for (j, pair) in missing.enumerated() {
        let vec = computed[j]
        result[pair.index] = vec
        let entry = CardEmbedding(cardId: pair.card.id, vector: vec, modelVersion: version)
        modelContext.insert(entry)
        byId[pair.card.id] = entry
      }
      try? modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    }

    return result
  }

  private func fetchCached(ids: [String], version: String) -> [CardEmbedding] {
    let needed = Set(ids)
    let predicate = #Predicate<CardEmbedding> { entry in
      needed.contains(entry.cardId) && entry.modelVersion == version
    }
    let descriptor = FetchDescriptor<CardEmbedding>(predicate: predicate)
    return (try? modelContext.fetch(descriptor)) ?? []
  }
}
