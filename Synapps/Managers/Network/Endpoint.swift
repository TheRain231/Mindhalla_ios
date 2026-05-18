//
//  Endpoint.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import Foundation

enum Endpoint {
  case getAllBooks
  case getBookById(id: String)
  case getBookTasks(bookId: String)
  case uploadBook(fileURL: URL)

  var path: String {
    switch self {
    case .getAllBooks:
      "/api/v1/books"
    case let .getBookById(id):
      "/api/v1/books/\(id)"
    case let .getBookTasks(bookId):
      "/api/v1/books/\(bookId)/tasks"
    case .uploadBook:
      "/api/v1/uploads"
    }
  }

  var method: HTTP.Method {
    switch self {
    case .getAllBooks, .getBookById, .getBookTasks:
      .get
    case .uploadBook:
      .post
    }
  }

  var request: URLRequest? {
    let urlString = Constants.serverURL + path
    let url: URL?

    switch self {
    case .uploadBook:
      var components = URLComponents(string: urlString)
      components?.queryItems = [
        URLQueryItem(name: "language", value: uploadLanguageQueryValue),
        URLQueryItem(name: "studyMode", value: "true"),
      ]
      url = components?.url
    default:
      url = URL(string: urlString)
    }

    guard let url else { return nil }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue

    switch self {
    case let .uploadBook(fileURL):
      let boundary = UUID().uuidString
      request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

      if let body = createMultipartBody(fileURL: fileURL, boundary: boundary) {
        request.httpBody = body
      } else {
        return nil
      }
    default:
      break
    }

    return request
  }

  private func createMultipartBody(fileURL: URL, boundary: String) -> Data? {
    guard let fileData = try? Data(contentsOf: fileURL) else {
      return nil
    }

    let filename = fileURL.lastPathComponent
    let mimeType = BookFileFormat.detect(from: fileURL)?.mimeType ?? "application/octet-stream"

    var body = Data()

    guard let boundaryStart = "--\(boundary)\r\n".data(using: .utf8),
          let contentDisposition = "Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8),
          let contentType = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
          let boundaryEnd = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
      return nil
    }

    body.append(boundaryStart)
    body.append(contentDisposition)
    body.append(contentType)

    body.append(fileData)

    body.append(boundaryEnd)

    return body
  }

  private var uploadLanguageQueryValue: String {
    let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
    return preferredLanguage.hasPrefix("ru") ? "ru" : "en"
  }
}
