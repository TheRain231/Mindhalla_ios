//
//  CardsView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftUI

struct CardsView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    VStack {
      cardsStack
    }
    .id(viewModel.viewId) // for "Reset Cards" button in Preview
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: backgroundColors(for: viewModel.topCard?.type),
        startPoint: .bottom,
        endPoint: .top
      )
    )
  }

  private var cardsStack: some View {
    CardSwiperView(
      cards: viewModel.cards,
      onCardSwiped: { swipeDirection, index in
        switch swipeDirection {
        case .left:
          print("Card swiped Left direction at index \(index)")
        case .right:
          print("Card swiped Right direction at index \(index)")
        case .undefined:
          print("Not enough movement for card to be swipen")
        }
      },
      currentIndex: $viewModel.topCardIndex
    ) { card in
      CardCardView(card: card)
    }
  }
}

private func backgroundColors(for type: CardType?) -> [Color] {
  switch type {
  case .thesis:
    [Color(UIColor(red: 220 / 255, green: 227 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
  case .concept:
    [Color(UIColor(red: 228 / 255, green: 221 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
  case .idea:
    [Color(UIColor(red: 245 / 255, green: 237 / 255, blue: 227 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 241 / 255, blue: 238 / 255, alpha: 1.0))]
  case .unknown, .none:
    [Color(.systemBackground)]
  }
}

#Preview("Interactive") {
  @Previewable var viewModel = MockViewModelFactory().createCardsViewModel()

  ZStack {
    CardsView(viewModel: viewModel)
      .ignoresSafeArea()

    VStack {
      Spacer()
      Button("Reset Cards") {
        viewModel.resetCards()
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

extension CardsView.ViewModel {
  fileprivate func resetCards() {
    viewId = UUID()
  }
}

#Preview() {
  CardsView(viewModel: MockViewModelFactory().createCardsViewModel())
    .ignoresSafeArea()
}
