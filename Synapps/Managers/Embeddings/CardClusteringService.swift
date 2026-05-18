import Foundation
import SwiftData
import WidgetKit

/// Greedy single-link clustering of cards by cosine similarity of their content embeddings.
/// Embeddings are cached in `CardEmbedding` keyed by `cardId` + `modelVersion`.
@MainActor
final class CardClusteringService {
  static let defaultThreshold: Float = 0.45

  struct Result {
    let clusters: [[Card]]
    let vectorsById: [String: [Float]]
  }

  private let modelContext: ModelContext
  let embeddingService: EmbeddingService

  init(modelContext: ModelContext, embeddingService: EmbeddingService) {
    self.modelContext = modelContext
    self.embeddingService = embeddingService
  }

  /// Returns groups of cards plus the per-card embedding vectors that produced them.
  /// Mean-link greedy merge: a candidate joins a cluster when its mean cosine to ALL
  /// existing members is ≥ threshold, avoiding chain-merging from single-link.
  func cluster(cards: [Card], threshold: Float = CardClusteringService.defaultThreshold) async throws -> Result {
    guard !cards.isEmpty else { return Result(clusters: [], vectorsById: [:]) }

    let vectors = try await embedAll(cards: cards)

    var clusters: [[Int]] = []
    for i in 0..<cards.count {
      let v = vectors[i]
      var bestCluster = -1
      var bestScore: Float = threshold
      for (idx, cluster) in clusters.enumerated() {
        var sum: Float = 0
        for member in cluster {
          sum += CosineSimilarity.cosine(v, vectors[member])
        }
        let mean = sum / Float(cluster.count)
        if mean >= bestScore {
          bestScore = mean
          bestCluster = idx
        }
      }
      if bestCluster >= 0 {
        clusters[bestCluster].append(i)
      } else {
        clusters.append([i])
      }
    }

    var vectorsById: [String: [Float]] = [:]
    vectorsById.reserveCapacity(cards.count)
    for (i, card) in cards.enumerated() {
      vectorsById[card.id] = vectors[i]
    }

    let grouped = clusters.map { idxs in idxs.map { cards[$0] } }
    return Result(clusters: grouped, vectorsById: vectorsById)
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
      // Чанкуем embed(batch:) — ONNX inference с большим batch'ем создаёт
      // огромный hidden tensor (batch × seqLen × hidden_dim × 4 байта) и крашит
      // приложение по jetsam memory limit на больших библиотеках (500+ карточек).
      let chunkSize = 32
      var index = 0
      while index < missing.count {
        let end = min(index + chunkSize, missing.count)
        let slice = Array(missing[index..<end])
        let texts = slice.map(\.card.content)
        let computed = try await embeddingService.embed(batch: texts)
        for (j, pair) in slice.enumerated() {
          let vec = computed[j]
          result[pair.index] = vec
          let entry = CardEmbedding(cardId: pair.card.id, vector: vec, modelVersion: version)
          modelContext.insert(entry)
          byId[pair.card.id] = entry
        }
        index = end
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
