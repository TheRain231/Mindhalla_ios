import Accelerate
import Foundation

enum CosineSimilarity {
  /// Cosine similarity between two equal-length vectors.
  /// For L2-normalized inputs this collapses to a dot product.
  static func cosine(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count, !a.isEmpty else { return 0 }
    var dot: Float = 0
    vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
    return dot
  }

  /// L2-normalize a vector in place.
  static func l2Normalize(_ v: inout [Float]) {
    var norm: Float = 0
    vDSP_svesq(v, 1, &norm, vDSP_Length(v.count))
    norm = sqrtf(norm)
    guard norm > 1e-12 else { return }
    var inv = 1 / norm
    vDSP_vsmul(v, 1, &inv, &v, 1, vDSP_Length(v.count))
  }
}
