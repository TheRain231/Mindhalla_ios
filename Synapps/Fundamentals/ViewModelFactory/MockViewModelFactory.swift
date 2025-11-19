//
//  MockViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import SwiftUI

final class MockViewModelFactory: ViewModelFactoryProtocol {
  let networkManager: NetworkManagerProtocol = MockNetworkManager()

  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  func createCardsViewModel(cardID: String) -> CardsView.ViewModel {
    CardsView.ViewModel(cardID: cardID, networkManager: networkManager)
  }

  func createHomeViewModel() -> HomeView.ViewModel {
    HomeView.ViewModel(networkManager: networkManager)
  }
}
