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
  case uploadBook(fileURL: URL)

  var path: String {
    switch self {
    case .getAllBooks:
      "/api/v1/books"
    case let .getBookById(id):
      "/api/v1/books/\(id)"
    case .uploadBook:
      "/api/v1/uploads"
    }
  }

  var method: HTTP.Method {
    switch self {
    case .getAllBooks, .getBookById:
      .get
    case .uploadBook:
      .post
    }
  }

  var request: URLRequest? {
    guard let url = URL(string: Constants.serverURL + path) else {
      return nil
    }

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
    let mimeType = "application/pdf"

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
}
