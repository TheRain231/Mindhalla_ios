//
//  BookTasksViewModel.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import Foundation

extension BookTasksView {
  @MainActor
  final class ViewModel: ObservableObject {
    enum ScreenState {
      case loading
      case failed
      case empty
      case ready(BookTasksResponse)
    }

    private let bookId: String
    private let networkManager: NetworkManagerProtocol
    private let prefetchedTasks: BookTasksResponse?

    @Published var screenState: ScreenState = .loading
    @Published private var selectedOptions: [String: String] = [:]

    init(bookId: String, networkManager: NetworkManagerProtocol, prefetchedTasks: BookTasksResponse? = nil) {
      self.bookId = bookId
      self.networkManager = networkManager
      self.prefetchedTasks = prefetchedTasks
      if let prefetchedTasks {
        screenState = prefetchedTasks.tasks.isEmpty && prefetchedTasks.isReady ? .empty : .ready(prefetchedTasks)
      }
    }

    func fetchIfNeeded() async {
      if case .ready = screenState { return }
      await load()
    }

    func forceReload() async {
      await load()
    }

    func selectOption(_ optionId: String, for taskId: String) {
      selectedOptions[taskId] = optionId
    }

    func selectedOptionId(for taskId: String) -> String? {
      selectedOptions[taskId]
    }

    private func load() async {
      screenState = .loading
      do {
        let response = try await networkManager.getBookTasks(bookId: bookId)
        screenState = response.tasks.isEmpty && response.isReady ? .empty : .ready(response)
      } catch {
        screenState = .failed
      }
    }
  }
}
