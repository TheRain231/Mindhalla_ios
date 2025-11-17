//
//  NetworkManager.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

import Foundation

final class NetworkManager: NetworkManagerProtocol {
  private let client: ClientProtocol

  init(client: ClientProtocol) {
    self.client = client
  }

  func getAllBooks() async throws -> [BookMetaResponse] {
    try await withCheckedThrowingContinuation { continuation in
      client.getAllBooks { response, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let response else {
          continuation.resume(throwing: NetworkError.invalidResponse("No data received for getAllBooks"))
          return
        }

        let books = response.books.map { BookMetaResponse(dto: $0) }
        continuation.resume(returning: books)
      }
    }
  }

  func uploadBook(_: URL) async throws -> String {
    // TODO: Реализовать загрузку файла
    ""
  }

  func getBook(by id: String) async throws -> BookFullResponse {
    try await withCheckedThrowingContinuation { continuation in
      client.getBookById(id: id) { response, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let response else {
          continuation.resume(throwing: NetworkError.invalidResponse("No data received for getBookById"))
          return
        }

        let book = BookFullResponse(dto: response)
        continuation.resume(returning: book)
      }
    }
  }
}
