import Foundation

protocol EmbeddingService: AnyObject, Sendable {
  var modelVersion: String { get }
  func embed(_ text: String) async throws -> [Float]
  func embed(batch texts: [String]) async throws -> [[Float]]
}

enum EmbeddingError: Error {
  case modelNotFound
  case tokenizerNotFound
  case sessionInitFailed(String)
  case inferenceFailed(String)
  case unexpectedOutputShape
}
