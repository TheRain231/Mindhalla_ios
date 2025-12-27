//
//  SavedView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 25.12.2025.
//

import SwiftUI

struct SavedView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(Card.mocks()) { book in
            NavigationLink(value: book) {
              CardCardView(card: book)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("saved_books")
    }
  }
}

#Preview {
  SavedView(viewModel: MockViewModelFactory().createSavedViewModel())
}
