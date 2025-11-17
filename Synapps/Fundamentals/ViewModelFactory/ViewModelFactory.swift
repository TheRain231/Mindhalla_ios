//
//  ViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation

final class ViewModelFactory: ViewModelFactoryProtocol {
  let networkManager: NetworkManagerProtocol

  init() {
    let urlSession = URLSession.shared
    let apiService = APIService(urlSession: urlSession)
    let client = Client(service: apiService)
    networkManager = NetworkManager(client: client)
  }

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
