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

    private var pendingBookId: String? {
      get { UserDefaults.standard.string(forKey: UserDefaultsKeys.pendingBookIdKey) }
      set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.pendingBookIdKey) }
    }

    private var pendingBookFilename: String? {
      get { UserDefaults.standard.string(forKey: UserDefaultsKeys.pendingBookFilenameKey) }
      set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.pendingBookFilenameKey) }
    }

    @Published var isLoading: Bool = false
    @Published var showAddBookModal: Bool = false
    @Published var showFileAccessAlert: Bool = false
    @Published var showDuplicateBookAlert: Bool = false
    @Published var uploadState: BookUploadState?
    @Published var loadTrigger = UUID()
    @Published var selectedBookForModePicker: BookMetaResponse?
    @Published var navigationRoute: HomeNavigationRoute?

    private var prefetchedBooksById: [String: BookByIdResponse] = [:]
    private var prefetchedTasksById: [String: BookTasksResponse] = [:]
    private var prefetchTaskByBookId: [String: Task<Void, Never>] = [:]

    init(networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.networkManager = networkManager
      self.modelContext = modelContext
    }

    deinit {
      uploadedBookPollTask?.cancel()
      prefetchTaskByBookId.values.forEach { $0.cancel() }
    }

    func didTapBook(_ book: BookMetaResponse) {
      selectedBookForModePicker = book
      prefetchBookData(bookId: book.id)
    }

    func openCardsMode() {
      guard let selectedBookForModePicker else { return }
      navigationRoute = .cards(
        bookId: selectedBookForModePicker.id,
        prefetchedBook: prefetchedBooksById[selectedBookForModePicker.id]
      )
      self.selectedBookForModePicker = nil
    }

    func openTasksMode() {
      guard let selectedBookForModePicker else { return }
      navigationRoute = .tasks(
        bookId: selectedBookForModePicker.id,
        prefetchedTasks: prefetchedTasksById[selectedBookForModePicker.id]
      )
      self.selectedBookForModePicker = nil
    }

    private func prefetchBookData(bookId: String) {
      if prefetchTaskByBookId[bookId] != nil { return }
      prefetchTaskByBookId[bookId] = Task { [weak self] in
        guard let self else { return }
        async let bookRequest: BookByIdResponse? = try? await self.networkManager.getBook(by: bookId)
        async let tasksRequest: BookTasksResponse? = try? await self.networkManager.getBookTasks(bookId: bookId)

        let (book, tasks) = await (bookRequest, tasksRequest)
        await MainActor.run {
          if let book {
            self.prefetchedBooksById[bookId] = book
          }
          if let tasks {
            self.prefetchedTasksById[bookId] = tasks
          }
          self.prefetchTaskByBookId.removeValue(forKey: bookId)
        }
      }
    }

    func onAddBookCompletion(result: Result<URL, Error>) {
      switch result {
      case let .success(url):
        let selectedFilename = url.lastPathComponent
        guard !isDuplicate(filename: selectedFilename) else {
          showDuplicateBookAlert = true
          return
        }
        lastUploadURL = url
        Task { @MainActor in
          uploadState = .loading
          uploadedBookPollTask?.cancel()
          do {
            let uploadInfo = try await networkManager.uploadBook(url)
            pendingBookId = uploadInfo.id
            pendingBookFilename = uploadInfo.filename
            insertPlaceholder(id: uploadInfo.id, filename: uploadInfo.filename)
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

    private func isDuplicate(filename: String) -> Bool {
      let descriptor = FetchDescriptor<BookMetaResponse>()
      let books = (try? modelContext.fetch(descriptor)) ?? []
      return books.contains { $0.filename == filename }
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
      resumePendingBookPollingIfNeeded()
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
        let detail = try await networkManager.getBook(by: bookId)
        print("[Synapps][BookByIdSync] ok, processingStatus=\(detail.processingStatus)")
        updatePlaceholder(id: bookId, with: detail)
        if detail.processingStatus == "done" || detail.processingStatus == "failed" {
          uploadedBookPollTask?.cancel()
          pendingBookId = nil
          pendingBookFilename = nil
        }
      } catch {
        print("[Synapps][BookByIdSync] error: \(error)")
      }
    }

    @MainActor
    private func resumePendingBookPollingIfNeeded() {
      guard let bookId = pendingBookId else { return }
      let descriptor = FetchDescriptor<BookMetaResponse>(predicate: #Predicate { $0.id == bookId })
      let existing = try? modelContext.fetch(descriptor).first
      if existing == nil {
        let filename = pendingBookFilename ?? bookId
        insertPlaceholder(id: bookId, filename: filename)
      } else if existing?.processingStatus == "done" {
        pendingBookId = nil
        pendingBookFilename = nil
        return
      }
      startPeriodicUploadedBookDetailSync(bookId: bookId)
    }

    @MainActor
    private func insertPlaceholder(id: String, filename: String) {
      let descriptor = FetchDescriptor<BookMetaResponse>(predicate: #Predicate { $0.id == id })
      if (try? modelContext.fetch(descriptor))?.isEmpty == false { return }
      let placeholder = BookMetaResponse(
        id: id,
        title: filename,
        editionNumber: 0,
        year: 0,
        publisher: nil,
        authors: [],
        genres: [],
        processingStatus: "in_progress",
        filename: filename
      )
      modelContext.insert(placeholder)
      try? modelContext.save()
    }

    @MainActor
    private func updatePlaceholder(id: String, with detail: BookByIdResponse) {
      let descriptor = FetchDescriptor<BookMetaResponse>(predicate: #Predicate { $0.id == id })
      guard let book = try? modelContext.fetch(descriptor).first else { return }
      book.processingStatus = detail.processingStatus
      book.filename = detail.filename
      book.totalChapters = detail.totalChapters
      book.processedChapters = detail.processedChapters
      if detail.processingStatus == "done" {
        book.title = detail.title
        book.editionNumber = detail.editionNumber
        book.year = detail.year
        book.publisher = detail.publisher.isEmpty ? nil : detail.publisher
        book.authors = detail.authorsBooks
        book.genres = detail.genresBooks
        book.coverImageUrl = detail.coverImageUrl
      }
      try? modelContext.save()
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
          if existingBook.processingStatus == "in_progress" {
            existingBook.processingStatus = "done"
            if existingBook.id == pendingBookId {
              pendingBookId = nil
              pendingBookFilename = nil
              uploadedBookPollTask?.cancel()
            }
          }
          existingBooksDict.removeValue(forKey: fetchedBook.id)
        } else {
          modelContext.insert(fetchedBook)
        }
      }

      for (_, bookToDelete) in existingBooksDict {
        guard bookToDelete.processingStatus != "in_progress" else { continue }
        modelContext.delete(bookToDelete)
      }

      try? modelContext.save()
    }

    func retryProcessing(bookId: String) {
      let descriptor = FetchDescriptor<BookMetaResponse>(predicate: #Predicate { $0.id == bookId })
      guard let book = try? modelContext.fetch(descriptor).first else { return }
      book.processingStatus = "in_progress"
      try? modelContext.save()
      pendingBookId = bookId
      Task { @MainActor in
        startPeriodicUploadedBookDetailSync(bookId: bookId)
      }
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

enum HomeNavigationRoute: Identifiable, Hashable {
  case cards(bookId: String, prefetchedBook: BookByIdResponse?)
  case tasks(bookId: String, prefetchedTasks: BookTasksResponse?)

  var id: String {
    switch self {
    case let .cards(bookId, _):
      return "cards-\(bookId)"
    case let .tasks(bookId, _):
      return "tasks-\(bookId)"
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
