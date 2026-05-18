import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.startAnimating()
    view.addSubview(activityIndicator)
    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])

    Task { await processInputItems() }
  }

  // MARK: - Input handling

  private func processInputItems() async {
    let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
      .flatMap { $0.attachments ?? [] } ?? []

    for (idx, provider) in providers.enumerated() {
      print("[Synapps][Share] provider[\(idx)] registeredTypeIdentifiers=\(provider.registeredTypeIdentifiers)")
    }

    for provider in providers {
      if let format = matchingFormat(in: provider) {
        print("[Synapps][Share] trying handleFile format=\(format.rawValue)")
        if await handleFile(provider: provider, format: format) { return }
      }
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        print("[Synapps][Share] trying handleGenericFileURL")
        if await handleGenericFileURL(provider: provider) { return }
      }
      if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        print("[Synapps][Share] trying handleWebURL")
        if await handleWebURL(provider: provider) { return }
      }
    }

    await presentError(String(localized: "Share.Error.UnsupportedFormat"))
  }

  private func matchingFormat(in provider: NSItemProvider) -> BookFileFormat? {
    BookFileFormat.allCases.first { provider.hasItemConformingToTypeIdentifier($0.utType.identifier) }
  }

  // MARK: - Sources

  /// Файл, явно соответствующий одному из BookFileFormat UTI (Files/Mail).
  private func handleFile(provider: NSItemProvider, format: BookFileFormat) async -> Bool {
    guard let tempURL = await loadFileRepresentation(provider: provider, typeIdentifier: format.utType.identifier) else {
      return false
    }
    return await enqueueAndComplete(sourceURL: tempURL, displayFilename: tempURL.lastPathComponent, format: format)
  }

  /// Файл с любым UTI, но известным расширением или magic-bytes — fallback для public.file-url.
  private func handleGenericFileURL(provider: NSItemProvider) async -> Bool {
    guard let tempURL = await loadFileRepresentation(provider: provider, typeIdentifier: UTType.fileURL.identifier) else {
      return false
    }
    let byExtension = BookFileFormat.detect(from: tempURL)
    let byMagic: BookFileFormat? = {
      let head = (try? Data(contentsOf: tempURL, options: .mappedIfSafe).prefix(512)) ?? Data()
      return BookFileFormat.detect(from: head)
    }()
    guard let format = byExtension ?? byMagic else {
      print("[Synapps][Share] handleGenericFileURL: format unknown for \(tempURL.lastPathComponent)")
      return false
    }
    return await enqueueAndComplete(sourceURL: tempURL, displayFilename: tempURL.lastPathComponent, format: format)
  }

  /// Веб-URL из Safari — скачиваем через URLSession.download (на диск, не в память).
  private func handleWebURL(provider: NSItemProvider) async -> Bool {
    guard let webURL: URL = await loadURL(provider: provider) else { return false }
    print("[Synapps][Share] webURL=\(webURL.absoluteString) scheme=\(webURL.scheme ?? "nil")")

    // file:// URL — это уже локальный файл, не нужно качать.
    if webURL.isFileURL {
      let byExtension = BookFileFormat.detect(from: webURL)
      let byMagic: BookFileFormat? = {
        let head = (try? Data(contentsOf: webURL, options: .mappedIfSafe).prefix(512)) ?? Data()
        return BookFileFormat.detect(from: head)
      }()
      guard let format = byExtension ?? byMagic else {
        await presentError(String(localized: "Share.Error.LocalUnknownFormat"))
        return true
      }
      return await enqueueAndComplete(sourceURL: webURL, displayFilename: webURL.lastPathComponent, format: format)
    }

    do {
      var request = URLRequest(url: webURL)
      // Часть сайтов отдаёт мусор/HTML без User-Agent и Accept (например, anti-bot).
      request.setValue(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        forHTTPHeaderField: "User-Agent"
      )
      request.setValue("application/pdf,application/epub+zip,application/x-fictionbook+xml,*/*", forHTTPHeaderField: "Accept")

      let (downloadURL, response) = try await URLSession.shared.download(for: request)
      let http = response as? HTTPURLResponse
      let suggested = response.suggestedFilename ?? webURL.lastPathComponent
      let contentType = http?.value(forHTTPHeaderField: "Content-Type") ?? response.mimeType ?? "nil"
      print("[Synapps][Share] downloaded status=\(http?.statusCode ?? -1) contentType=\(contentType) suggested=\(suggested) size=\(((try? FileManager.default.attributesOfItem(atPath: downloadURL.path)[.size]) as? Int) ?? -1)")

      let format = detectFormat(downloadURL: downloadURL, suggestedFilename: suggested, response: response)
      guard let format else {
        try? FileManager.default.removeItem(at: downloadURL)
        let hint = "Content-Type: \(contentType)"
        await presentError(String(format: String(localized: "Share.Error.UnknownFormat"), hint))
        return true
      }
      let displayName = suggested.isEmpty ? "book.\(format.fileExtension)" : suggested
      return await enqueueAndComplete(sourceURL: downloadURL, displayFilename: displayName, format: format)
    } catch {
      print("[Synapps][Share] download error: \(error)")
      await presentError(String(format: String(localized: "Share.Error.DownloadFailed"), error.localizedDescription))
      return true
    }
  }

  // MARK: - Format detection for downloads

  private func detectFormat(downloadURL: URL, suggestedFilename: String, response: URLResponse) -> BookFileFormat? {
    // 1) Самый надёжный сигнал — HTTP Content-Type / MIME, отданный сервером.
    let http = response as? HTTPURLResponse
    let rawType = (http?.value(forHTTPHeaderField: "Content-Type") ?? response.mimeType ?? "")
      .lowercased()
    let mime = rawType.split(separator: ";").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? rawType
    if let byMime = BookFileFormat.allCases.first(where: { $0.mimeType == mime }) {
      return byMime
    }

    // 2) Расширение из suggestedFilename (или URL fallback). Если расширение в одной из allowedTypes.
    if let byExtension = BookFileFormat(rawValue: (suggestedFilename as NSString).pathExtension.lowercased()) {
      return byExtension
    }

    // 3) Magic-bytes — последний шанс, если сервер врёт про MIME / расширение отсутствует.
    let head = (try? Data(contentsOf: downloadURL, options: .mappedIfSafe).prefix(512)) ?? Data()
    return BookFileFormat.detect(from: head)
  }

  // MARK: - Enqueue + open main app

  private func enqueueAndComplete(sourceURL: URL, displayFilename: String, format: BookFileFormat) async -> Bool {
    do {
      _ = try PendingUploadStore.enqueue(fileURL: sourceURL, suggestedTitle: displayFilename, format: format)
    } catch {
      await presentError(String(localized: "Share.Error.SaveFailed"))
      return true
    }
    openHostApp()
    await MainActor.run {
      self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    return true
  }

  private func openHostApp() {
    guard let url = URL(string: "synapps://import-pending") else { return }
    var responder: UIResponder? = self
    while let current = responder {
      if let application = current as? UIApplication {
        application.open(url, options: [:], completionHandler: nil)
        return
      }
      responder = current.next
    }
  }

  // MARK: - Bridges to NSItemProvider callbacks

  private func loadFileRepresentation(provider: NSItemProvider, typeIdentifier: String) async -> URL? {
    await withCheckedContinuation { continuation in
      provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
        guard let url else {
          continuation.resume(returning: nil)
          return
        }
        let tmp = FileManager.default.temporaryDirectory
          .appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
          try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
          let dest = tmp.appendingPathComponent(url.lastPathComponent)
          try FileManager.default.copyItem(at: url, to: dest)
          continuation.resume(returning: dest)
        } catch {
          continuation.resume(returning: nil)
        }
      }
    }
  }

  private func loadURL(provider: NSItemProvider) async -> URL? {
    await withCheckedContinuation { continuation in
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        if let url = item as? URL {
          continuation.resume(returning: url)
        } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
          continuation.resume(returning: url)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }

  // MARK: - Errors

  @MainActor
  private func presentError(_ message: String) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
        self?.extensionContext?.cancelRequest(withError: NSError(domain: "SynappsShareExtension", code: 0))
        continuation.resume()
      })
      present(alert, animated: true)
    }
  }
}
