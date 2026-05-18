import Foundation

struct PendingUpload: Codable, Equatable, Identifiable {
  let id: UUID
  let storedFilename: String
  let displayFilename: String
  let format: BookFileFormat
  let enqueuedAt: Date
}

enum PendingUploadStore {
  private static let userDefaultsKey = "synapps.pendingUploads"
  private static let pendingDirectoryName = "PendingUploads"
  private static let lock = NSLock()

  static func containerURL() -> URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
  }

  static func pendingDirectory() -> URL? {
    guard let container = containerURL() else { return nil }
    let dir = container.appendingPathComponent(pendingDirectoryName, isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
  }

  static func enqueue(fileURL: URL, suggestedTitle: String?, format: BookFileFormat) throws -> PendingUpload {
    lock.lock()
    defer { lock.unlock() }

    guard let dir = pendingDirectory() else {
      throw NSError(domain: "PendingUploadStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "App Group container unavailable"])
    }

    let id = UUID()
    let storedFilename = "\(id.uuidString).\(format.fileExtension)"
    let destination = dir.appendingPathComponent(storedFilename)
    try FileManager.default.copyItem(at: fileURL, to: destination)

    let display = suggestedTitle?.isEmpty == false ? suggestedTitle! : fileURL.lastPathComponent
    let upload = PendingUpload(
      id: id,
      storedFilename: storedFilename,
      displayFilename: display,
      format: format,
      enqueuedAt: Date()
    )

    var current = readUnlocked()
    current.append(upload)
    writeUnlocked(current)

    return upload
  }

  static func peekAll() -> [PendingUpload] {
    lock.lock()
    defer { lock.unlock() }
    return readUnlocked()
  }

  static func remove(_ upload: PendingUpload) {
    lock.lock()
    defer { lock.unlock() }

    var current = readUnlocked()
    current.removeAll { $0.id == upload.id }
    writeUnlocked(current)

    if let url = fileURLUnlocked(for: upload) {
      try? FileManager.default.removeItem(at: url)
    }
  }

  static func fileURL(for upload: PendingUpload) -> URL? {
    fileURLUnlocked(for: upload)
  }

  // MARK: - Private

  private static func defaults() -> UserDefaults? {
    UserDefaults(suiteName: AppGroup.identifier)
  }

  private static func readUnlocked() -> [PendingUpload] {
    guard let data = defaults()?.data(forKey: userDefaultsKey) else { return [] }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return (try? decoder.decode([PendingUpload].self, from: data)) ?? []
  }

  private static func writeUnlocked(_ uploads: [PendingUpload]) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(uploads) else { return }
    defaults()?.set(data, forKey: userDefaultsKey)
  }

  private static func fileURLUnlocked(for upload: PendingUpload) -> URL? {
    pendingDirectory()?.appendingPathComponent(upload.storedFilename)
  }
}
