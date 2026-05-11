import Foundation

@MainActor
final class AutoTagScheduler {
  private let service: AutoTaggingService
  private let debounce: Duration

  private var task: Task<Void, Never>?

  init(service: AutoTaggingService, debounce: Duration = .seconds(8)) {
    self.service = service
    self.debounce = debounce
  }

  func scheduleRun() {
    task?.cancel()
    task = Task { [weak self] in
      guard let self else { return }
      do {
        try await Task.sleep(for: self.debounce)
      } catch {
        return
      }
      try? await self.service.runFullPass()
    }
  }

  /// Bypasses debounce — run a full pass immediately. Useful for manual retag triggers.
  func runImmediately() {
    task?.cancel()
    task = Task { [weak self] in
      guard let self else { return }
      try? await self.service.runFullPass()
    }
  }
}
