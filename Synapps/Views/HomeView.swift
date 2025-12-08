//
//  HomeView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftData
import SwiftUI

struct HomeView: View {
  @StateObject var viewModel: ViewModel
  @Environment(\.viewModelFactory) var factory
  @Query private var books: [BookMetaResponse]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(books) { book in
            NavigationLink(value: book) {
              BookOverview(book: book)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
      .fileImporter(isPresented: $viewModel.showAddBookModal, allowedContentTypes: [.pdf], onCompletion: viewModel.onAddBookCompletion)
      .navigationTitle("my_books")
      .navigationDestination(for: BookMetaResponse.self) { book in
        CardsView(viewModel: factory.createCardsViewModel(cardID: book.id))
          .ignoresSafeArea()
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            viewModel.addBookAction()
          } label: {
            Image(systemName: "plus")
          }
        }
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
