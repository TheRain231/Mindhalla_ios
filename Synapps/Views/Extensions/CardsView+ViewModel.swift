//
//  CardsView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftUI

extension CardsView {
  final class ViewModel: ObservableObject {
    let cardID: String
    let networkManager: NetworkManagerProtocol

    @Published var cards: [Card]
    @Published var topCardIndex: Int
    @Published var viewId = UUID()

    init(cardID: String, networkManager: NetworkManagerProtocol) {
      self.cardID = cardID
      self.networkManager = networkManager

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
            cards = fetchedCards
            topCardIndex = cards.count - 1
          }
        } catch {
          print(error.localizedDescription)
          // TODO: добавить обработку ошибок
        }
      }
    }
  }
}
