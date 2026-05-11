//
//  CardsView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftData
import SwiftUI

struct CardsView: View {
  @Environment(\.viewModelFactory) var factory
  @StateObject private var viewModel: ViewModel
  @Query private var persistedBooks: [BookByIdResponse]
  var onTasksTap: (() -> Void)?

  init(viewModel: ViewModel, onTasksTap: (() -> Void)? = nil) {
    _viewModel = StateObject(wrappedValue: viewModel)
    self.onTasksTap = onTasksTap
    let bookId = viewModel.cardID
    _persistedBooks = Query(filter: #Predicate<BookByIdResponse> { $0.id == bookId })
  }

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
        overlayBottomView
      }
    )
    .onChange(of: persistedBooks.first?.cardIdsSignature) { _, _ in
      viewModel.applyPersistedBook(persistedBooks.first)
    }
    .sheet(isPresented: $viewModel.isSaveViewPresented) {
      if let card = viewModel.topCard {
        SaveBottomsheetView(
          viewModel: factory.createSaveBottomsheetViewModel(card: card),
          onSaved: { viewModel.showSavedMessage() }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
      }
    }
  }
}

extension CardsView {
  @ViewBuilder
  private var savedToSectionMessage: some View {
    if viewModel.isSavedMessageVisible {
      HStack {
        Text("CardsView.SavedToANewCollection")
          .foregroundStyle(.black.opacity(0.8))
          .font(.system(size: 13))
          .fontWeight(.regular)
        // TODO: add a link to a section
        Spacer()
        Button {
          viewModel.isSavedMessageVisible = false
        } label: {
          Image(systemName: "xmark")
            .foregroundStyle(.gray.opacity(0.6))
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(hex: "F5F9FF"))
          .stroke(Color(hex: "9DC0EE"))
      )
      .padding(.horizontal, 43)
      .padding(.bottom, 30)
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }

  private var buttonsStack: some View {
    HStack {
      Button {
        onTasksTap?()
      } label: {
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
        .opacity(viewModel.topCardIndex >= 0 ? 1 : 0)

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
  }

  private var overlayBottomView: some View {
    VStack {
      savedToSectionMessage
      buttonsStack
    }
    .padding(.bottom, 60)
  }
}

extension CardsView.ViewModel {
  fileprivate func resetCards() {
    viewId = UUID()
  }
}

#if DEBUG
#Preview("Interactive") {
  let factory = MockViewModelFactory()
  let viewModel = factory.createCardsViewModel(cardID: "insteractive_preview")
  ZStack {
    CardsView(viewModel: viewModel)
      .modelContainer(factory.modelContainer)
      .ignoresSafeArea()
  }
}

#Preview() {
  let factory = MockViewModelFactory()
  CardsView(viewModel: factory.createCardsViewModel(cardID: "preview"))
    .modelContainer(factory.modelContainer)
    .ignoresSafeArea()
}
#endif
