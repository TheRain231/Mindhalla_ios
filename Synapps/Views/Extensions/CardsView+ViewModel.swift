//
//  CardsView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftUI

extension CardsView {
  final class ViewModel: ObservableObject {
    @Published var cards: [Card]
    @Published var topCardIndex: Int
    @Published var viewId = UUID()

    init(cards: [Card]) {
      self.cards = cards
      topCardIndex = cards.count - 1
    }

    var topCard: Card? {
      if topCardIndex < cards.count, topCardIndex >= 0 {
        cards[topCardIndex]
      } else {
        nil
      }
    }
  }
}
