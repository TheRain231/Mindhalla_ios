//
//  HomeView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftUI

struct HomeView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(viewModel.books) { book in
            BookOverview(book: book)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("my_books")
    }
  }
}

#Preview {
  HomeView(viewModel: MockViewModelFactory().createHomeViewModel())
}
