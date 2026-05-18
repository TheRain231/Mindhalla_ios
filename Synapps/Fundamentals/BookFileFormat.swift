import Foundation
import UniformTypeIdentifiers

enum BookFileFormat: String, Codable, CaseIterable {
  case pdf
  case epub
  case fb2

  var fileExtension: String { rawValue }

  var mimeType: String {
    switch self {
    case .pdf:  "application/pdf"
    case .epub: "application/epub+zip"
    case .fb2:  "application/x-fictionbook+xml"
    }
  }

  var utType: UTType {
    switch self {
    case .pdf:  .pdf
    case .epub: .epub
    case .fb2:  UTType(filenameExtension: "fb2") ?? .xml
    }
  }

  static var allowedUTTypes: [UTType] {
    allCases.map(\.utType)
  }

  static func detect(from url: URL) -> BookFileFormat? {
    BookFileFormat(rawValue: url.pathExtension.lowercased())
  }

  /// Распознавание формата по содержимому файла (magic-bytes / sniffing).
  /// Защита от случая, когда URL отдаёт не то, что обещано расширением (HTML вместо PDF и т.п.).
  static func detect(from data: Data) -> BookFileFormat? {
    if data.starts(with: [0x25, 0x50, 0x44, 0x46, 0x2D]) {
      return .pdf
    }
    if data.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
      return .epub
    }
    if let text = String(data: data.prefix(512), encoding: .utf8),
       text.contains("<?xml"),
       text.contains("<FictionBook") {
      return .fb2
    }
    return nil
  }
}
