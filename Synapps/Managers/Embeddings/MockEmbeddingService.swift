import Foundation

/// Deterministic, hash-based fake embedding for previews and tests — does not load ONNX.
final class MockEmbeddingService: EmbeddingService, @unchecked Sendable {
  let modelVersion = "mock-v1"
  private let dim = 64

  func embed(_ text: String) async throws -> [Float] {
    makeVector(text)
  }

  func embed(batch texts: [String]) async throws -> [[Float]] {
    texts.map { makeVector($0) }
  }

  private func makeVector(_ text: String) -> [Float] {
    var vec = [Float](repeating: 0, count: dim)
    for (i, scalar) in text.unicodeScalars.enumerated() {
      vec[i % dim] += Float(scalar.value % 97) / 97.0
    }
    CosineSimilarity.l2Normalize(&vec)
    return vec
  }
}
