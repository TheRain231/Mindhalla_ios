//
//  CardsView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftData
import SwiftUI

struct CardsView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    CardStackView(
      viewModel: viewModel,
      onCardSwiped: { swipeDirection, index in
        switch swipeDirection {
        case .left:
          print("Card swiped Left direction at index \(index)")
        case .right:
          viewModel.saveCard(viewModel.items[index])
          print("Card swiped Right direction at index \(index)")
        case .undefined:
          print("Not enough movement for card to be swipen")
        }
      },
      content: { card in
        CardCardView(card: card)
      },
      overlay: {
        buttonsStack
      }
    )
    .sheet(isPresented: $viewModel.isSaveViewPresented) {
        EmptyView()
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
    
    private var buttonsStack: some View {
        HStack {
            NavigationLink(value: QuizDestination()) {
                Image(systemName: "questionmark.app.fill")
                    .foregroundColor(.gray.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.2), radius: 7)
                    )
            }
            Spacer()

            Text("\(viewModel.currentCardIndex + 1) / \(viewModel.items.count)")
            
            Spacer()
            
            Button {
                viewModel.isSaveViewPresented.toggle()
            } label: {
                Image("bookmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "9B60E9"))
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.2), radius: 7)
                    )
            }
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 60)
    }
}

#Preview("Interactive") {
  @Previewable var viewModel = MockViewModelFactory().createCardsViewModel(cardID: "insteractive_preview")

  ZStack {
    CardsView(viewModel: viewModel)
      .ignoresSafeArea()
  }
}

extension CardsView.ViewModel {
  fileprivate func resetCards() {
    viewId = UUID()
  }
}

#Preview() {
  CardsView(viewModel: MockViewModelFactory().createCardsViewModel(cardID: "preview"))
    .ignoresSafeArea()
}
