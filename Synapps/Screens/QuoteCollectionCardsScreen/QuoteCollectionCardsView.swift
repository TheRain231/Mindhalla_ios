import SwiftData
import SwiftUI

struct QuoteCollectionCardsScreen: View {
  let quoteCollection: QuoteCollection
  @State private var viewModel: QuoteCollectionCardsViewModel

  init(quoteCollection: QuoteCollection, factory: ViewModelFactoryProtocol) {
    self.quoteCollection = quoteCollection
    _viewModel = State(initialValue: factory.createQuoteCollectionCardsViewModel())
  }

  var body: some View {
    QuoteCollectionCardsView(
      viewModel: viewModel,
      quoteCollection: quoteCollection
    )
  }
}

struct QuoteCollectionCardsView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: QuoteCollectionCardsViewModel
  let quoteCollection: QuoteCollection

  var body: some View {
    VStack {
      searchField
      CardTypePaginationView(
        cardTypes: viewModel.presentTypes,
        onTap: viewModel.toggleTypeFilter
      )
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(viewModel.filteredCards) { card in
            cardRow(card: card)
          }
        }
        .animation(.easeInOut(duration: 0.55), value: viewModel.filteredCards.map(\.id))
        .padding()
      }
      .task {
        if viewModel.cards.isEmpty {
          viewModel.fetchCards(for: quoteCollection.cardIds)
        }
      }
      .navigationTitle(quoteCollection.title)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Menu {
//              ShareLink(item: sharePayload(for: quoteCollection)) {
//                Label("Поделиться", systemImage: "square.and.arrow.up")
//              }
            Button(role: .destructive) {
              viewModel.showDeleteCollectionConfirmation = true
            } label: {
              Label("Menu.RemoveCollection", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .alert("RemoveCollectionAlert.Title", isPresented: $viewModel.showDeleteCollectionConfirmation) {
        Button("Remove", role: .destructive) {
          viewModel.delete(quoteCollection)
          dismiss()
        }

        Button("Cancel", role: .cancel) {}
      }
    }
    .alert(
      "QuoteCollectionCardsView.ConfirmRemove.Title",
      isPresented: $viewModel.showRemovalConfirmation
    ) {
      Button("QuoteCollectionCardsView.ConfirmRemove.Button", role: .destructive) {
        if let id = viewModel.cardIdPendingRemoval {
          viewModel.removeCardFromCollection(cardId: id, collectionId: quoteCollection.id)
        }
        viewModel.cardIdPendingRemoval = nil
      }

      Button("QuoteCollectionCardsView.Cancel", role: .cancel) {
        viewModel.cardIdPendingRemoval = nil
      }
    } message: {
      Text("QuoteCollectionCardsView.ConfirmRemove.Message")
    }
    .onChange(of: viewModel.showRemovalConfirmation) { _, isShowing in
      if !isShowing {
        viewModel.cardIdPendingRemoval = nil
      }
    }
  }
}

extension QuoteCollectionCardsView {
  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("QuoteCollectionCardsView.SearchCard", text: $viewModel.searchText)
        .textFieldStyle(.plain)
    }
    .padding(8)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
    .padding(.top, 4)
  }

  private func cardRow(card: Card) -> some View {
    CardCardView(card: card)
      .contextMenu {
        Button {
          // TODO: airdrop?
        } label: {
          Label("QuoteCollectionCardsView.Menu.Share", systemImage: "square.and.arrow.up")
        }

        Button {
          // TODO: навигация к экрану изучения по card.id
        } label: {
          Label("QuoteCollectionCardsView.Menu.Study", systemImage: "book.pages")
        }

        Button(role: .destructive) {
          viewModel.cardIdPendingRemoval = card.id
          viewModel.showRemovalConfirmation = true
        } label: {
          Label("QuoteCollectionCardsView.Menu.RemoveFromCollection", systemImage: "trash")
        }
      }
  }
}

#Preview {
  let factory = MockViewModelFactory()

  QuoteCollectionCardsScreen(
    quoteCollection: QuoteCollection.mock(),
    factory: factory
  )
  .modelContainer(factory.modelContainer)
}
