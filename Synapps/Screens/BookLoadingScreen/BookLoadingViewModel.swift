import SwiftUI
import UIKit

@MainActor @Observable
final class BookLoadingViewModel {
  private var rotationTask: Task<Void, Never>?
  private var currentMessageIndex: Int = 0

  var currentMessage: LocalizedStringKey {
    BookLoadingViewModel.messages[currentMessageIndex]
  }

  private let showMessageInterval: TimeInterval = 2.5

  func startTimer() {
    guard rotationTask == nil else { return }
    rotationTask = Task { [weak self] in
      guard let self else { return }
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(self.showMessageInterval))
        if Task.isCancelled { break }
        withAnimation {
          self.currentMessageIndex = (self.currentMessageIndex + 1) % BookLoadingViewModel.messages.count
        }
      }
    }
  }

  func stopTimer() {
    rotationTask?.cancel()
    rotationTask = nil
  }
}

extension BookLoadingViewModel {
  static let messages: [LocalizedStringKey] = [
    "Loading.DynamicMessage.Squeezing out the information juice",
    "Loading.DynamicMessage.Translating into human",
    "Loading.DynamicMessage.Flipping through 300 pages",
    "Loading.DynamicMessage.Separating facts from water",
    "Loading.DynamicMessage.Condensing chapters into theses",
    "Loading.DynamicMessage.Highlighting key ideas with a marker",
    "Loading.DynamicMessage.Extracting meaning between the lines",
    "Loading.DynamicMessage.Putting the arguments in order",
    "Loading.DynamicMessage.Washing the text from officialese",
    "Loading.DynamicMessage.Digesting ideas without losing taste",
    "Loading.DynamicMessage.Turning chapters into checklists",
    "Loading.DynamicMessage.Finding repetitions and cross out unnecessary ones",
    "Loading.DynamicMessage.Connecting thoughts into a system",
    "Loading.DynamicMessage.Preparing a short outline for submission",
    "Loading.DynamicMessage.Scanning quotes from greats",
  ]
}

extension BookLoadingViewModel {
  private enum Localized {}
}
