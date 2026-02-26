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
      
    private var lastUploadURL: URL?

    @Published var showAddBookModal: Bool = false
    @Published var showFileAccessAlert: Bool = false
    @Published var uploadState: BookUploadState?

    init(networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.networkManager = networkManager
      self.modelContext = modelContext
    }

    func onAddBookCompletion(result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            lastUploadURL = url
            Task { @MainActor in
                uploadState = .loading
                do {
                    _ = try await networkManager.uploadBook(url)
                    uploadState = .success
                } catch {
                    uploadState = uploadState(from: error)
                }
            }
        default:
            break
        }
    }

    func fetch() {
      Task {
        do {
          let fetchedBooks = try await networkManager.getAllBooks()
          await MainActor.run {
            syncBooks(fetchedBooks: fetchedBooks) // TODO: Надо разобраться и исправить warning
          }
        } catch {
          // TODO: добавить обработку ошибок
          print(error)
        }
      }
    }
      
    func retryUpload() {
        guard let url = lastUploadURL else {
            uploadState = nil
            return
        }
        onAddBookCompletion(result: .success(url))
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
        let fileAccessAllowed = UserDefaults.standard.bool(forKey: UserDefaultsKeys.fileAccessAllowedKey)

        if fileAccessAllowed {
            showAddBookModal = true
        } else {
            showFileAccessAlert = true
        }
    }

    /// Вызывается при нажатии «Разрешить» в алерте доступа к файлам — открывает окно выбора файла.
    func confirmFileAccessAndOpenPicker() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.fileAccessAllowedKey)
        showFileAccessAlert = false
        showAddBookModal = true
    }

    /// Вызывается при отказе в алерте — окно выбора не открываем, при следующем нажатии «+» алерт покажется снова.
    func declineFileAccess() {
      showFileAccessAlert = false
    }
  }
}

// MARK: - Book Upload State

extension HomeView.ViewModel {
    enum BookUploadState: Identifiable {
        case loading
        case success
        case processingError   // не удалось обработать (формат/декодирование)
        case uploadError       // книга не была загружена (общая)
        case networkError      // потеряно соединение с интернетом
        
        var id: String { String(describing: self) }
    }
    
    private func uploadState(from error: Error) -> BookUploadState {
        guard let networkError = error as? NetworkError else {
            return .uploadError
        }
        switch networkError {
        case .urlSessionError:
            return .networkError
        case .decodingError, .invalidResponse:
            return .processingError
        case .serverError:
            return .uploadError
        }
    }
}
