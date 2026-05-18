import Foundation
import SwiftData

extension BookTasksView {
  @MainActor
  final class ViewModel: ObservableObject {
    enum ScreenState {
      case loading
      case failed
      case empty
      case ready(BookTasksResponse)
    }

    let bookId: String
    private let networkManager: NetworkManagerProtocol
    private let modelContext: ModelContext
    private let prefetchedTasks: BookTasksResponse?

    @Published var screenState: ScreenState = .loading
    @Published private(set) var displayTasks: [BookTask] = []
    @Published var currentIndex: Int = 0
    @Published var isCompleted: Bool = false
    @Published private var selectedOptions: [String: Set<String>] = [:]
    @Published private var submittedTasks: Set<String> = []
    @Published private var hintsVisible: Set<String> = []
    private var lastAppliedTasksSignature: String?

    init(
      bookId: String,
      networkManager: NetworkManagerProtocol,
      modelContext: ModelContext,
      prefetchedTasks: BookTasksResponse? = nil
    ) {
      self.bookId = bookId
      self.networkManager = networkManager
      self.modelContext = modelContext
      self.prefetchedTasks = prefetchedTasks
      if let prefetchedTasks {
        applyResponse(prefetchedTasks, shuffleDisplay: true, resetProgress: true)
      }
    }

    func fetchIfNeeded() async {
      if case .ready = screenState { return }
      await load()
    }

    func forceReload() async {
      await load()
    }

    func applyPersisted(_ response: BookTasksResponse?) {
      guard let response, response.id == bookId else { return }
      let sig = response.tasksSyncSignature
      if lastAppliedTasksSignature == sig, case .ready = screenState {
        return
      }
      applyResponse(response, shuffleDisplay: true, resetProgress: true)
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
      submittedTasks.removeAll()
      hintsVisible.removeAll()
      isCompleted = false
    }

    func shuffle() {
      guard case let .ready(response) = screenState else { return }
      displayTasks = Self.shuffledTasks(from: response.tasks)
      restart()
    }

    func correctAnswersCount(in tasks: [BookTask]) -> Int {
      tasks.filter { isFullyCorrect(task: $0) }.count
    }

    private static func shuffledTasks(from tasks: [BookTask]) -> [BookTask] {
      tasks.shuffled()
    }

    private func applyResponse(_ response: BookTasksResponse, shuffleDisplay: Bool, resetProgress: Bool) {
      lastAppliedTasksSignature = response.tasksSyncSignature
      if response.tasks.isEmpty, !response.isReady {
        screenState = .ready(response)
        displayTasks = []
        if resetProgress { restart() }
        return
      }
      if response.tasks.isEmpty, response.isReady {
        screenState = .empty
        displayTasks = []
        if resetProgress { restart() }
        return
      }
      screenState = .ready(response)
      displayTasks = shuffleDisplay ? Self.shuffledTasks(from: response.tasks) : response.tasks
      if resetProgress {
        restart()
      }
    }

    private func load() async {
      screenState = .loading
      do {
        let response = try await networkManager.getBookTasks(bookId: bookId)
        let persisted = try BookTasksResponse.persist(response, modelContext: modelContext)
        applyResponse(persisted, shuffleDisplay: true, resetProgress: true)
      } catch {
        let bid = bookId
        let descriptor = FetchDescriptor<BookTasksResponse>(predicate: #Predicate { $0.id == bid })
        if let local = try? modelContext.fetch(descriptor).first, !local.tasks.isEmpty || !local.isReady {
          applyResponse(local, shuffleDisplay: displayTasks.isEmpty, resetProgress: displayTasks.isEmpty)
        } else {
          screenState = .failed
        }
      }
    }
  }
}
