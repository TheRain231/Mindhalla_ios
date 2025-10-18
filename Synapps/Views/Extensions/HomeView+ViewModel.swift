//
//  HomeView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftUI

extension HomeView {
  final class ViewModel: ObservableObject {
    @Published var books: [BookSummary]

    init(books: [BookSummary]) {
      self.books = books
    }
  }
}
