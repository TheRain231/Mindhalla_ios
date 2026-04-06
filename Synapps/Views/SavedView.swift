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

  var body: some View {
    NavigationStack {
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
        QuoteCollectionCardsView(
          viewModel: factory.createQuoteCollectionCardsViewModel(),
          quoteCollection: collection
        )
      }
      .navigationLinkIndicatorVisibility(.hidden)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          addButton
        }
      }
      .ignoresSafeArea(edges: .bottom)
    }
  }
}

extension SavedView {
  private var collectionsContent: some View {
    VStack {
      searchField
      List {
        ForEach(collections) { collection in
          collectionRow(collection)
        }
        .onDelete(perform: { indexSet in
          for index in indexSet {
            viewModel.delete(collections[index])
          }
        })
      }
      .listStyle(.plain)
    }
  }

  private var cardsContent: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        ForEach(cards) { book in
          CardCardView(card: book)
        }
      }
      .padding(.top)
      .padding(.horizontal)
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

  private var addButton: some View {
    Button {
      // TODO: add collection or card?
    } label: {
      Image(systemName: "plus")
    }
  }

  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("search_collection", text: $viewModel.searchText)
        .textFieldStyle(.plain)
    }
    .padding(8)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
    .padding(.top, 8)
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

  SavedView(viewModel: factory.createSavedViewModel())
    .modelContainer(factory.modelContainer)
}
