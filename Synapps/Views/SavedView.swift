//
//  SavedView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 25.12.2025.
//

import SwiftData
import SwiftUI

struct SavedView: View {
  @StateObject var viewModel: ViewModel
  @Environment(\.viewModelFactory) var factory
  @Query var cards: [Card]
  @Query(sort: \QuoteCollection.title) var collections: [QuoteCollection]
  @State private var cardPendingDeletion: Card?
  @State private var navigationPath = NavigationPath()
  @Binding var deepLink: DeepLink?

  var body: some View {
    NavigationStack(path: $navigationPath) {
      Picker("Picker State", selection: $viewModel.pickerState) {
        ForEach(PickerState.allCases) { state in
          Text(state.rawValue.capitalized)
        }
      }
      .padding()
      .pickerStyle(.segmented)

      TabView(selection: $viewModel.pickerState) {
        collectionsContent.tag(PickerState.collections)
        cardsContent.tag(PickerState.cards)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .navigationTitle("saved_books")
      .navigationDestination(for: QuoteCollection.self) { collection in
        QuoteCollectionCardsScreen(
          quoteCollection: collection,
          factory: factory
        )
      }
      .navigationLinkIndicatorVisibility(.hidden)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          addButton
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .onChange(of: deepLink) { _, link in
        guard let link else { return }
        switch link {
        case let .collection(id):
          if let collection = collections.first(where: { $0.id == id }) {
            viewModel.pickerState = .collections
            navigationPath.append(collection)
          }
        case .saved:
          navigationPath = NavigationPath()
        }
        deepLink = nil
      }
    }
    .alert("Alert.RemoveCardTitle", isPresented: cardDeletionIsPresented) {
      Button("Remove", role: .destructive) {
        if let cardPendingDeletion {
          withAnimation(.linear(duration: 0.5)) {
            viewModel.deleteCard(cardPendingDeletion, allCards: cards)
          }
        }
        cardPendingDeletion = nil
      }

      Button("Cancel", role: .cancel) {
        cardPendingDeletion = nil
      }
    } message: {
      Text("Alert.RemoveCardSubtitle")
    }
  }
}

extension SavedView {
  private var collectionsContent: some View {
    let filtered = viewModel.filteredCollections(from: collections)
    return VStack {
      collectionSearchField
      if collections.isEmpty {
        EmptyStateView(
          icon: "folder",
          title: "SavedView.Collections.Empty.Title",
          message: "SavedView.Collections.Empty.Message"
        )
      } else if filtered.isEmpty {
        EmptyStateView(
          icon: "magnifyingglass",
          title: "SavedView.Search.Empty.Title"
        )
      } else {
        List {
          ForEach(filtered) { collection in
            collectionRow(collection)
          }
        }
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.plain)
      }
    }
  }

  private var cardsContent: some View {
    let filtered = viewModel.filteredCards(from: cards)
    return VStack {
      cardSearchField
      if cards.isEmpty {
        EmptyStateView(
          icon: "rectangle.on.rectangle",
          title: "SavedView.Cards.Empty.Title",
          message: "SavedView.Cards.Empty.Message"
        )
      } else if filtered.isEmpty {
        EmptyStateView(
          icon: "magnifyingglass",
          title: "SavedView.Search.Empty.Title"
        )
      } else {
        CardTypePaginationView(
          cardTypes: viewModel.presentTypes(from: cards),
          onTap: viewModel.toggleTypeFilter
        )
        ScrollView {
          LazyVStack(spacing: 20) {
            ForEach(filtered) { card in
              cardRow(card)
            }
          }
          .animation(.easeInOut(duration: 0.55), value: cards.map(\.id))
          .padding(.top)
          .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
      }
    }
  }

  private func collectionRow(_ collection: QuoteCollection) -> some View {
    NavigationLink(value: collection) {
      HStack {
        Text(collection.title)

        Spacer()

        HStack(spacing: 30) {
          Text(collection.quoteCount.description)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal)
      }
    }
  }

  private func cardRow(_ card: Card) -> some View {
    CardCardView(card: card)
      .contextMenu {
        ShareLink(item: viewModel.shareText(for: card)) {
          Label("QuoteCollectionCardsView.Menu.Share", systemImage: "square.and.arrow.up")
        }

        Button(role: .destructive) {
          cardPendingDeletion = card
        } label: {
          Label("QuoteCollectionCardsView.Menu.RemoveFromCollection", systemImage: "trash")
        }
      }
  }

  private var addButton: some View {
    Button {
      // TODO: add collection or card?
    } label: {
      Image(systemName: "plus")
    }
  }

  private var collectionSearchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("search_collection", text: $viewModel.collectionSearchText)
        .textFieldStyle(.plain)
    }
    .padding(8)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
    .padding(.top, 8)
  }

  private var cardSearchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("QuoteCollectionCardsView.SearchCard", text: $viewModel.cardSearchText)
        .textFieldStyle(.plain)
    }
    .padding(8)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
    .padding(.top, 8)
  }

  private var cardDeletionIsPresented: Binding<Bool> {
    Binding(
      get: { cardPendingDeletion != nil },
      set: { isPresented in
        if !isPresented {
          cardPendingDeletion = nil
        }
      }
    )
  }
}

extension SavedView {
  enum PickerState: String, CaseIterable, Identifiable {
    case collections
    case cards
    var id: Self { self }
  }
}

#Preview {
  let factory = MockViewModelFactory()

  SavedView(viewModel: factory.createSavedViewModel(), deepLink: .constant(nil))
    .modelContainer(factory.modelContainer)
}
