//
//  HomeView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftUI

struct HomeView: View {
  @StateObject var viewModel: ViewModel
  @Environment(\.viewModelFactory) var factory

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(viewModel.books) { book in
            NavigationLink(value: book) {
              BookOverview(book: book)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("my_books")
      .navigationDestination(for: BookMetaResponse.self) { book in
        CardsView(viewModel: factory.createCardsViewModel(cardID: book.id))
          .ignoresSafeArea()
      }
    }
    .onAppear {
      viewModel.fetch()
    }
  }
}

#Preview {
  HomeView(viewModel: MockViewModelFactory().createHomeViewModel())
}
