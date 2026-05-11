//
//  CardsView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftData
import SwiftUI
import WidgetKit

extension CardsView {
  final class ViewModel: ObservableObject {
    let cardID: String
    let networkManager: NetworkManagerProtocol
    let modelContext: ModelContext
    let autoTagScheduler: AutoTagScheduler
    private let prefetchedBook: BookByIdResponse?

    @Published var cards: [Card]
    @Published var topCardIndex: Int
    @Published var viewId = UUID()
    @Published var isSaveViewPresented: Bool = false
    @Published var isSavedMessageVisible: Bool = false

    init(cardID: String, networkManager: NetworkManagerProtocol, modelContext: ModelContext, prefetchedBook: BookByIdResponse? = nil, autoTagScheduler: AutoTagScheduler) {
      self.cardID = cardID
      self.networkManager = networkManager
      self.modelContext = modelContext
      self.prefetchedBook = prefetchedBook
      self.autoTagScheduler = autoTagScheduler

      self.cards = [] // Обязательно вызвать fetch() на onAppear
      self.topCardIndex = 0
    }

    var topCard: Card? {
      print("topCardIndex: \(topCardIndex)")
      if topCardIndex < cards.count, topCardIndex >= 0 {
        return cards[topCardIndex]
      } else {
        return nil
      }
    }

    func fetch() {
      Task {
        do {
          let book = try await fetchBook()
          await MainActor.run {
            try? BookByIdResponse.persist(book, modelContext: modelContext)
            applyCardsFromBook(book)
          }
        } catch {
          await MainActor.run {
            let descriptor = FetchDescriptor<BookByIdResponse>(predicate: #Predicate { $0.id == cardID })
            if let local = try? modelContext.fetch(descriptor).first, !local.cards.isEmpty {
              applyCardsFromBook(local)
            }
            print(error.localizedDescription)
          }
        }
      }
    }

    func applyPersistedBook(_ book: BookByIdResponse?) {
      guard let book, book.id == cardID, !book.cards.isEmpty else { return }
      applyCardsFromBook(book)
    }

    private func applyCardsFromBook(_ book: BookByIdResponse) {
      cards = book.cards
      topCardIndex = max(0, cards.count - 1)
    }

    private func fetchBook() async throws -> BookByIdResponse {
      if let prefetchedBook {
        return prefetchedBook
      }
      return try await networkManager.getBook(by: cardID)
    }

    @MainActor
    func saveCard(_ card: Card) {
      let targetId = card.id
      let predicate = #Predicate<Card> { $0.id == targetId }
      var descriptor: FetchDescriptor<Card> = FetchDescriptor(predicate: predicate)
      descriptor.fetchLimit = 1

      if let existing = try? modelContext.fetch(descriptor).first {
        if existing.savedAt == nil {
          existing.bookId = cardID
          existing.savedAt = .now
          try? modelContext.save()
          WidgetCenter.shared.reloadAllTimelines()
        }
        return
      }
      card.bookId = cardID
      modelContext.insert(card)
      try? modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    }

    func showSavedMessage() {
      isSavedMessageVisible = true
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(3))
        isSavedMessageVisible = false
      }
    }
  }
}

extension CardsView.ViewModel: CardStackViewModel {
  var items: [Card] {
    get { cards }
    set {
      cards = newValue
      SpacedRepetitionScheduler.recordStudySession()
    }
  }

  func cardType(for item: Card) -> CardType? {
    item.type
  }
}
