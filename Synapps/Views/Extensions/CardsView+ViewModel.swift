//
//  CardsView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftData
import SwiftUI

extension CardsView {
  final class ViewModel: ObservableObject {
    let cardID: String
    let networkManager: NetworkManagerProtocol
    let modelContext: ModelContext

    @Published var cards: [Card]
    @Published var topCardIndex: Int
    @Published var viewId = UUID()
      @Published var isSaveViewPresented: Bool = false

    init(cardID: String, networkManager: NetworkManagerProtocol, modelContext: ModelContext) {
      self.cardID = cardID
      self.networkManager = networkManager
      self.modelContext = modelContext

      self.cards = [] // Обязательно вызвать fetch() на onAppear
      self.topCardIndex = 0
    }

    var topCard: Card? {
      if topCardIndex < cards.count, topCardIndex >= 0 {
        cards[topCardIndex]
      } else {
        nil
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
      // Добавляем карточку в контекст только если её там ещё нет (по уникальному id)
      let targetId = card.id
      let predicate = #Predicate<Card> { $0.id == targetId }
      var descriptor: FetchDescriptor<Card> = FetchDescriptor(predicate: predicate)
      descriptor.fetchLimit = 1

      if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
        modelContext.insert(card)
        try? modelContext.save()
      }
    }
  }
}

extension CardsView.ViewModel: CardStackViewModel {
  var items: [Card] {
    get { cards }
    set { cards = newValue }
  }

  func cardType(for item: Card) -> CardType? {
    item.type
  }
}
