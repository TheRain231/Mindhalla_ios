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
    @Published var currentIndex: Int = 0
    @Published var isCompleted: Bool = false
    @Published private var selectedOptions: [String: Set<String>] = [:]
    @Published private var submittedTasks: Set<String> = []
    @Published private var hintsVisible: Set<String> = []

    init(bookId: String, networkManager: NetworkManagerProtocol, prefetchedTasks: BookTasksResponse? = nil) {
      self.bookId = bookId
      self.networkManager = networkManager
      self.prefetchedTasks = prefetchedTasks
      if let prefetchedTasks {
        let shuffled = Self.withShuffledTasks(prefetchedTasks)
        screenState = shuffled.tasks.isEmpty && shuffled.isReady ? .empty : .ready(shuffled)
      }
    }

    func fetchIfNeeded() async {
      if case .ready = screenState { return }
      await load()
    }

    func forceReload() async {
      await load()
    }

    func isMultipleChoice(task: BookTask) -> Bool {
      task.correctOptionIds.count > 1
    }

    func toggleOption(_ optionId: String, for task: BookTask) {
      guard !submittedTasks.contains(task.id) else { return }
      var current = selectedOptions[task.id] ?? []
      if isMultipleChoice(task: task) {
        if current.contains(optionId) {
          current.remove(optionId)
        } else {
          current.insert(optionId)
        }
        selectedOptions[task.id] = current
      } else {
        selectedOptions[task.id] = [optionId]
        submittedTasks.insert(task.id)
      }
    }

    func submit(for taskId: String) {
      guard !submittedTasks.contains(taskId) else { return }
      guard !(selectedOptions[taskId] ?? []).isEmpty else { return }
      submittedTasks.insert(taskId)
    }

    func selectedOptionIds(for taskId: String) -> Set<String> {
      selectedOptions[taskId] ?? []
    }

    func isSelected(optionId: String, for taskId: String) -> Bool {
      selectedOptions[taskId]?.contains(optionId) ?? false
    }

    func isAnswered(taskId: String) -> Bool {
      submittedTasks.contains(taskId)
    }

    func isFullyCorrect(task: BookTask) -> Bool {
      let selected = selectedOptions[task.id] ?? []
      return selected == Set(task.correctOptionIds)
    }

    func showHint(for taskId: String) {
      hintsVisible.insert(taskId)
    }

    func isHintVisible(for taskId: String) -> Bool {
      hintsVisible.contains(taskId)
    }

    func goToNext(taskCount: Int) {
      if currentIndex >= taskCount - 1 {
        isCompleted = true
      } else {
        currentIndex += 1
      }
    }

    func restart() {
      currentIndex = 0
      selectedOptions = [:]
      submittedTasks = []
      hintsVisible = []
      isCompleted = false
    }

    func shuffle() {
      guard case let .ready(response) = screenState else { return }
      let shuffled = Self.withShuffledTasks(response)
      screenState = .ready(shuffled)
      restart()
    }

    private static func withShuffledTasks(_ response: BookTasksResponse) -> BookTasksResponse {
      BookTasksResponse(
        id: response.id,
        processingStatus: response.processingStatus,
        totalChapters: response.totalChapters,
        processedChapters: response.processedChapters,
        tasks: response.tasks.shuffled()
      )
    }

    func correctAnswersCount(in tasks: [BookTask]) -> Int {
      tasks.filter { isFullyCorrect(task: $0) }.count
    }

    private func load() async {
      screenState = .loading
      do {
        let response = try await networkManager.getBookTasks(bookId: bookId)
        let shuffled = Self.withShuffledTasks(response)
        screenState = shuffled.tasks.isEmpty && shuffled.isReady ? .empty : .ready(shuffled)
      } catch {
        screenState = .failed
      }
    }
  }
}
