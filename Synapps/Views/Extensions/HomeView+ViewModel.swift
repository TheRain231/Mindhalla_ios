//
//  HomeView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftData
import SwiftUI

extension HomeView {
  final class ViewModel: ObservableObject {
    let networkManager: NetworkManagerProtocol
    let modelContext: ModelContext

    @Published var isLoading: Bool = false

    @Published var showAddBookModal: Bool = false
    var onAddBookCompletion: (Result<URL, Error>) -> Void

    @Published var loadTrigger = UUID()

    init(networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.networkManager = networkManager
      self.modelContext = modelContext

      self.onAddBookCompletion = { result in
        switch result {
        case let .success(url):
          Task {
            do {
              let uploadResult = try await networkManager.uploadBook(url)
              print(uploadResult) // TODO: Поменять на алерт или что-нибудь
            } catch {
              // TODO: добавить обработку ошибок
              print("Ошибка загрузки файла: \(error)")
            }
          }
        default:
          break
        }
      }
    }

    func reload() {
      loadTrigger = UUID()
    }

    @MainActor
    func fetch() async {
      isLoading = true
      defer { isLoading = false }

      do {
        let fetchedBooks = try await networkManager.getAllBooks()
        syncBooks(fetchedBooks: fetchedBooks)
      } catch {
        print(error)
      }
    }

    private func syncBooks(fetchedBooks: [BookMetaResponse]) {
      let descriptor = FetchDescriptor<BookMetaResponse>()
      guard let existingBooks = try? modelContext.fetch(descriptor) else {
        fetchedBooks.forEach { modelContext.insert($0) }
        return
      }

      var existingBooksDict = Dictionary(uniqueKeysWithValues: existingBooks.map { ($0.id, $0) })

      for fetchedBook in fetchedBooks {
        if let existingBook = existingBooksDict[fetchedBook.id] {
          existingBook.title = fetchedBook.title
          existingBook.editionNumber = fetchedBook.editionNumber
          existingBook.year = fetchedBook.year
          existingBook.publisher = fetchedBook.publisher
          existingBook.authors = fetchedBook.authors
          existingBook.genres = fetchedBook.genres
          existingBook.coverImageUrl = fetchedBook.coverImageUrl
          existingBooksDict.removeValue(forKey: fetchedBook.id)
        } else {
          modelContext.insert(fetchedBook)
        }
      }

      for (_, bookToDelete) in existingBooksDict {
        modelContext.delete(bookToDelete)
      }

      try? modelContext.save()
    }

    func addBookAction() {
      showAddBookModal = true
    }
  }
}
