//
//  MockNetworkManager.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation

final class MockNetworkManager: NetworkManagerProtocol {
  func getAllBooks() async throws -> [BookMetaResponse] {
    (0..<10).map { _ in BookMetaResponse.mock() }
  }

  func getBook(by id: String) async throws -> BookFullResponse {
    .init(id: id, title: "", editionNumber: 0, year: 0, publisher: "", language: "", pages: 0, cards: Card.mocks() + [Card.mock(type: .unknown)], authorsBooks: [], genresBooks: []) // Заполним когда будет использоваться
  }

  func uploadBook(_: URL) async throws -> UploadFileInfoResponse {
    UploadFileInfoResponse(
      id: UUID().uuidString,
      s3Key: "mock/s3/key",
      filename: "mock.pdf",
      mimetype: "application/pdf",
      size: 1024
    )
  }
}
