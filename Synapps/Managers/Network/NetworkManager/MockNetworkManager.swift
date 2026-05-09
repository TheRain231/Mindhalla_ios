//
//  MockNetworkManager.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation

#if DEBUG
final class MockNetworkManager: NetworkManagerProtocol {
  func getAllBooks() async throws -> [BookMetaResponse] {
    try await Task.sleep(for: .seconds(2))
    return (0..<10).map { _ in BookMetaResponse.mock() }
  }

  func getBook(by id: String) async throws -> BookByIdResponse {
    .init(id: id, title: "", editionNumber: 0, year: 0, publisher: "", language: "", pages: 0, cards: Card.mocks() + [Card.mock(type: .unknown)], authorsBooks: [], genresBooks: []) // Заполним когда будет использоваться
  }

  func getBookTasks(bookId: String) async throws -> BookTasksResponse {
    BookTasksResponse(
      id: bookId,
      processingStatus: "done",
      totalChapters: 10,
      processedChapters: 10,
      tasks: [
        BookTask(
          id: UUID().uuidString,
          title: "Какая главная идея главы?",
          options: [
            BookTaskOption(id: "1", text: "Пересказ фактов"),
            BookTaskOption(id: "2", text: "Поиск причин и следствий"),
            BookTaskOption(id: "3", text: "Только определения"),
          ],
          correctOptionIds: ["2"],
          hint: "Сфокусируйся на связях между событиями.",
          explanation: "В этой главе важнее понимать причинно-следственные связи."
        ),
      ]
    )
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
#endif
