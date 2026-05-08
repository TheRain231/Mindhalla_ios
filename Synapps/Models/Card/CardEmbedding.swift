import Foundation
import SwiftData

@Model
final class CardEmbedding {
  @Attribute(.unique) var cardId: String
  var vector: Data
  var modelVersion: String
  var updatedAt: Date

  init(cardId: String, vector: [Float], modelVersion: String, updatedAt: Date = .now) {
    self.cardId = cardId
    self.vector = vector.withUnsafeBufferPointer { Data(buffer: $0) }
    self.modelVersion = modelVersion
    self.updatedAt = updatedAt
  }

  var floats: [Float] {
    vector.withUnsafeBytes { raw -> [Float] in
      let buf = raw.bindMemory(to: Float.self)
      return Array(buf)
    }
  }

  func setFloats(_ values: [Float]) {
    vector = values.withUnsafeBufferPointer { Data(buffer: $0) }
  }
}
