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
  case uploadBook(request: UploadRequestDTO)

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
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    switch self {
    case let .uploadBook(uploadRequest):
      if let jsonData = try? JSONEncoder().encode(uploadRequest) {
        request.httpBody = jsonData
      }
    default:
      break
    }

    return request
  }
}
