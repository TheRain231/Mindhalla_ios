//
//  MockViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import SwiftUI

final class MockViewModelFactory: ViewModelFactoryProtocol {
  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  func createCardsViewModel() -> CardsView.ViewModel {
    CardsView.ViewModel(cards: Card.mocks())
  }

  func createHomeViewModel() -> HomeView.ViewModel {
    HomeView.ViewModel(books: (0..<10).map { _ in BookMetaResponse.mock() })
  }
}
