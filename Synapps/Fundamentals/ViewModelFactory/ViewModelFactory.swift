//
//  ViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation

final class ViewModelFactory: ViewModelFactoryProtocol {
  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  func createCardsViewModel() -> CardsView.ViewModel {
    CardsView.ViewModel(cards: [])
  }

  func createHomeViewModel() -> HomeView.ViewModel {
    HomeView.ViewModel(books: [])
  }
}
