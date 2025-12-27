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
  @Query private var cards: [Card]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(cards) { book in
            CardCardView(card: book)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("saved_books")
    }
  }
}

#Preview {
  let factory = MockViewModelFactory()

  SavedView(viewModel: factory.createSavedViewModel())
    .modelContainer(factory.modelContainer)
}
