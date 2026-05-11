import Foundation
import OnnxRuntimeBindings
import Tokenizers

/// Local sentence embedding service using `distiluse-base-multilingual-cased-v2` exported to ONNX.
/// Produces L2-normalized 512-dim vectors suitable for cosine similarity comparison.
///
/// Bundle layout (under `Synapps/Resources/MLModels/Distiluse/`):
///   - `distiluse-multilingual.onnx`  (int8-quantized)
///   - `tokenizer.json`
///   - `tokenizer_config.json`
actor ONNXEmbeddingService: EmbeddingService {
  let modelVersion = "distiluse-v2-q8"

  private let modelResourceName = "distiluse-multilingual"
  private let tokenizerFolderName = "Distiluse"
  private let maxLength = 128
  private let embeddingDim = 512

  private var loaded: Loaded?

  private struct Loaded {
    let env: ORTEnv
    let session: ORTSession
    let tokenizer: any Tokenizer
    let outputName: String
  }

  func embed(_ text: String) async throws -> [Float] {
    let result = try await embed(batch: [text])
    return result[0]
  }

  func embed(batch texts: [String]) async throws -> [[Float]] {
    guard !texts.isEmpty else { return [] }
    let ctx = try await ensureLoaded()

    let encoded = texts.map { ctx.tokenizer.encode(text: $0) }
    let truncated = encoded.map { Array($0.prefix(maxLength)) }
    let seqLen = truncated.map(\.count).max() ?? 0
    let batchSize = truncated.count

    var inputIds = [Int64](repeating: 0, count: batchSize * seqLen)
    var attentionMask = [Int64](repeating: 0, count: batchSize * seqLen)
    for (b, ids) in truncated.enumerated() {
      for (t, id) in ids.enumerated() {
        inputIds[b * seqLen + t] = Int64(id)
        attentionMask[b * seqLen + t] = 1
      }
    }

    let shape: [NSNumber] = [NSNumber(value: batchSize), NSNumber(value: seqLen)]
    let inputIdsValue = try makeInt64Tensor(values: inputIds, shape: shape)
    let attentionValue = try makeInt64Tensor(values: attentionMask, shape: shape)

    let outputs: [String: ORTValue]
    do {
      outputs = try ctx.session.run(
        withInputs: ["input_ids": inputIdsValue, "attention_mask": attentionValue],
        outputNames: Set([ctx.outputName]),
        runOptions: nil
      )
    } catch {
      throw EmbeddingError.inferenceFailed(error.localizedDescription)
    }
    guard let out = outputs[ctx.outputName] else {
      throw EmbeddingError.unexpectedOutputShape
    }

    let info = try out.tensorTypeAndShapeInfo()
    let outShape = info.shape.map(\.intValue)
    let raw = try out.tensorData() as Data
    let floats = raw.withUnsafeBytes { buf -> [Float] in
      let p = buf.bindMemory(to: Float.self)
      return Array(p)
    }

    return try meanPoolAndNormalize(
      hidden: floats,
      shape: outShape,
      attentionMask: attentionMask,
      batchSize: batchSize,
      seqLen: seqLen
    )
  }

  // MARK: - Loading

  private func ensureLoaded() async throws -> Loaded {
    if let loaded { return loaded }

    guard let modelURL = Bundle.main.url(forResource: modelResourceName, withExtension: "onnx") else {
      throw EmbeddingError.modelNotFound
    }
    guard let tokenizerURL = Bundle.main.url(forResource: "tokenizer", withExtension: "json", subdirectory: tokenizerFolderName)
      ?? Bundle.main.url(forResource: "tokenizer", withExtension: "json") else {
      throw EmbeddingError.tokenizerNotFound
    }
    let tokenizerFolder = tokenizerURL.deletingLastPathComponent()

    let env: ORTEnv
    let session: ORTSession
    do {
      env = try ORTEnv(loggingLevel: .warning)
      let options = try ORTSessionOptions()
      try options.setIntraOpNumThreads(2)
      session = try ORTSession(env: env, modelPath: modelURL.path, sessionOptions: options)
    } catch {
      throw EmbeddingError.sessionInitFailed(error.localizedDescription)
    }

    let tokenizer: any Tokenizer
    do {
      tokenizer = try await AutoTokenizer.from(modelFolder: tokenizerFolder)
    } catch {
      throw EmbeddingError.sessionInitFailed("tokenizer: \(error.localizedDescription)")
    }

    let outputName = (try? session.outputNames().first) ?? "last_hidden_state"

    let loaded = Loaded(env: env, session: session, tokenizer: tokenizer, outputName: outputName)
    self.loaded = loaded
    return loaded
  }

  // MARK: - Helpers

  private func makeInt64Tensor(values: [Int64], shape: [NSNumber]) throws -> ORTValue {
    let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
    let mutable = NSMutableData(data: data)
    return try ORTValue(tensorData: mutable, elementType: .int64, shape: shape)
  }

  /// Mean-pool token embeddings over attention mask, then L2-normalize per row.
  private func meanPoolAndNormalize(
    hidden: [Float],
    shape: [Int],
    attentionMask: [Int64],
    batchSize: Int,
    seqLen: Int
  ) throws -> [[Float]] {
    // Expected hidden shape: [batch, seq, hidden]
    guard shape.count == 3, shape[0] == batchSize, shape[1] == seqLen else {
      throw EmbeddingError.unexpectedOutputShape
    }
    let hiddenDim = shape[2]

    var pooled: [[Float]] = []
    pooled.reserveCapacity(batchSize)

    for b in 0..<batchSize {
      var row = [Float](repeating: 0, count: hiddenDim)
      var count: Float = 0
      for t in 0..<seqLen {
        guard attentionMask[b * seqLen + t] == 1 else { continue }
        let base = (b * seqLen + t) * hiddenDim
        for h in 0..<hiddenDim {
          row[h] += hidden[base + h]
        }
        count += 1
      }
      if count > 0 {
        let inv: Float = 1 / count
        for h in 0..<hiddenDim {
          row[h] *= inv
        }
      }
      CosineSimilarity.l2Normalize(&row)
      pooled.append(row)
    }
    return pooled
  }
}
