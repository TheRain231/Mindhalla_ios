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
    private var uploadedBookPollTask: Task<Void, Never>?

    @Published var isLoading: Bool = false
    @Published var showAddBookModal: Bool = false
    @Published var showFileAccessAlert: Bool = false
    @Published var uploadState: BookUploadState?
    @Published var loadTrigger = UUID()

    init(networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.networkManager = networkManager
      self.modelContext = modelContext
    }

    deinit {
      uploadedBookPollTask?.cancel()
    }

    func onAddBookCompletion(result: Result<URL, Error>) {
      switch result {
      case let .success(url):
        lastUploadURL = url
        Task { @MainActor in
          uploadState = .loading
          uploadedBookPollTask?.cancel()
          do {
            let uploadInfo = try await networkManager.uploadBook(url)
            await fetch(silent: true)
            uploadState = .success
            startPeriodicUploadedBookDetailSync(bookId: uploadInfo.id)
          } catch {
            uploadState = uploadState(from: error)
          }
        }
      default:
        break
      }
    }

    func reload() {
      uploadedBookPollTask?.cancel()
      uploadedBookPollTask = nil
      loadTrigger = UUID()
    }

    /// Первый запрос + опрос каждые 30 с (`getAllBooks`), пока экран открыт. Отменяется при уходе с `HomeView` или смене `loadTrigger`.
    @MainActor
    func startPeriodicBooksSync() async {
      await fetch(silent: false)
      let intervalNs: UInt64 = 30 * 1_000_000_000
      while !Task.isCancelled {
        do {
          try await Task.sleep(nanoseconds: intervalNs)
        } catch {
          break
        }
        guard !Task.isCancelled else { break }
        await fetch(silent: true)
      }
    }

    /// После успешной загрузки файла — `GET /books/{id}` сразу и далее каждые 30 с, пока задача не отменена (новая загрузка, `reload()`, `deinit`).
    @MainActor
    private func startPeriodicUploadedBookDetailSync(bookId: String) {
      uploadedBookPollTask?.cancel()
      uploadedBookPollTask = Task { @MainActor in
        let intervalNs: UInt64 = 30 * 1_000_000_000
        await refreshUploadedBookDetail(bookId: bookId)
        while !Task.isCancelled {
          do {
            try await Task.sleep(nanoseconds: intervalNs)
          } catch {
            break
          }
          guard !Task.isCancelled else { break }
          await refreshUploadedBookDetail(bookId: bookId)
        }
      }
    }

    @MainActor
    private func refreshUploadedBookDetail(bookId: String) async {
      do {
        print("[Synapps][BookByIdSync] GET /books/\(bookId)")
        _ = try await networkManager.getBook(by: bookId)
        print("[Synapps][BookByIdSync] ok")
      } catch {
        print("[Synapps][BookByIdSync] error: \(error)")
      }
    }

    @MainActor
    func fetch(silent: Bool = false) async {
      if !silent {
        isLoading = true
      }
      defer {
        if !silent {
          isLoading = false
        }
      }

      do {
        print("[Synapps][BooksSync] GET /api/v1/books silent=\(silent)")
        let fetchedBooks = try await networkManager.getAllBooks()
        syncBooks(fetchedBooks: fetchedBooks)
        print("[Synapps][BooksSync] ok, count=\(fetchedBooks.count)")
      } catch {
        print("[Synapps][BooksSync] error: \(error)")
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
    case processingError // не удалось обработать (формат/декодирование)
    case uploadError // книга не была загружена (общая)
    case networkError // потеряно соединение с интернетом

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
    default:
      return .uploadError
    }
  }
}
