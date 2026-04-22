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

    @Published var cards: [Card]
    @Published var topCardIndex: Int
    @Published var viewId = UUID()
    @Published var isSaveViewPresented: Bool = false
    @Published var isSavedMessageVisible: Bool = false

    init(cardID: String, networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.cardID = cardID
      self.networkManager = networkManager
      self.modelContext = modelContext

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
          let fetchedCards = try await networkManager.getBook(by: cardID).cards
          await MainActor.run {
            cards = fetchedCards // TODO: Надо разобраться и исправить warning
            topCardIndex = cards.count - 1
          }
        } catch {
          print(error.localizedDescription)
          // TODO: добавить обработку ошибок
        }
      }
    }

    func saveCard(_ card: Card) {
      let targetId = card.id
      let predicate = #Predicate<Card> { $0.id == targetId }
      var descriptor: FetchDescriptor<Card> = FetchDescriptor(predicate: predicate)
      descriptor.fetchLimit = 1

      if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
        modelContext.insert(card)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
        showSavedMessage()
      }
    }

    private func showSavedMessage() {
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
