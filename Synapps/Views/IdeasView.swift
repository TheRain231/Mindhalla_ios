//
//  IdeasView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftUI

struct IdeasView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    VStack {
      cardsStack
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: backgroundColors(for: viewModel.topCard?.type), // пока не разобрался как получать нужный цвет
        startPoint: .bottom,
        endPoint: .top
      )
      .ignoresSafeArea()
    )
  }

  private var cardsStack: some View {
    CardSwiperView(
      ideas: viewModel.ideas,
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
    ) { idea in
      IdeaCardView(idea: idea)
    }
  }
}

private func backgroundColors(for type: IdeaType?) -> [Color] {
  switch type {
  case .Thesis:
    [Color(UIColor(red: 220 / 255, green: 227 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
  case .Concept:
    [Color(UIColor(red: 228 / 255, green: 221 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
  case .Quote:
    [Color(UIColor(red: 245 / 255, green: 237 / 255, blue: 227 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 241 / 255, blue: 238 / 255, alpha: 1.0))]
  case .none:
    [Color(.systemBackground)]
  }
}

#Preview("Interactive") {
  @Previewable var viewModel: IdeasView.ViewModel = .init(ideas: Idea.mocks())

  ZStack {
    IdeasView(viewModel: viewModel)

    VStack {
      Spacer()
      Button("Reset Ideas") {
        viewModel.resetIdeas()
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

extension IdeasView.ViewModel {
  fileprivate func resetIdeas() {
    ideas = Idea.mocks()
  }
}

#Preview() {
  IdeasView(viewModel: .init(ideas: Idea.mocks()))
}
