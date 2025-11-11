//
//  NetworkManager.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

import Foundation
import OpenAPIURLSession

final class NetworkManager: NetworkManagerProtocol {
  private let client: Client

  init(client: Client) {
    self.client = client
  }

  func getAllBooks() async throws -> [BookMetaResponse] {
    let response = try await client.mock_get_books_api_v1_books_get()

    switch response {
    case let .ok(okResponse):
      let dto: Components.Schemas.BooksMetaResponse = try okResponse.body.json
      return dto.books.map { BookMetaResponse(dto: $0) }
    case let .undocumented(statusCode, _):
      throw NetworkError.invalidStatus(statusCode)
    }
  }

  func getBook(by id: String) async throws -> BookFullResponse {
    let response = try await client.mock_get_book_by_id_api_v1_books__book_id__get(
      path: .init(book_id: id)
    )

    switch response {
    case let .ok(okResponse):
      let dto = try okResponse.body.json
      return BookFullResponse(dto: dto)
    case let .undocumented(statusCode: statusCode, _):
      throw NetworkError.invalidStatus(statusCode)
    case .unprocessableContent:
      throw NetworkError.decodingFailed
    }
  }
}
