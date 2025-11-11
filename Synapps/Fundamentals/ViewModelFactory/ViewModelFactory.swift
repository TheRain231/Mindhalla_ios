//
//  ViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

final class ViewModelFactory: ViewModelFactoryProtocol {
  let client: Client
  let networkManager: NetworkManagerProtocol

  init() {
    do {
      let serverURL = try Servers.Server1.url()
      let transport = URLSessionTransport()
      client = Client(
        serverURL: serverURL,
        transport: transport
      )
      networkManager = NetworkManager(client: client)
    } catch {
      fatalError("OpenAPI.json has no url. Please, insert correct url. \nError: \(error.localizedDescription)")
    }
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
