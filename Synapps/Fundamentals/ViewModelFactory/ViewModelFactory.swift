//
//  ViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import SwiftData

final class ViewModelFactory: ViewModelFactoryProtocol {
  let networkManager: NetworkManagerProtocol
  let modelContainer: ModelContainer

  init() {
    let urlSession = URLSession.shared
    let apiService = APIService(urlSession: urlSession)
    let tokenStore = AuthTokenStore()
    let authSession = AuthSession(store: tokenStore, rawService: apiService)
    let authenticatedService = AuthenticatedAPIService(inner: apiService, authSession: authSession)
    let client = Client(service: authenticatedService)
    networkManager = NetworkManager(client: client)
    modelContainer = {
      do {
        let container = try SharedModelStore.makeContainer()
        #if DEBUG
        print("SwiftData store: \(SharedModelStore.makeConfiguration().url.path(percentEncoded: false))")
        #endif
        return container
      } catch {
        fatalError("Could not create ModelContainer for SwiftData: \(error)")
      }
    }()
  }

  @MainActor
  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  @MainActor
  func createCardsViewModel(cardID: String) -> CardsView.ViewModel {
    CardsView.ViewModel(cardID: cardID, networkManager: networkManager, modelContext: modelContainer.mainContext)
  }

  @MainActor
  func createHomeViewModel() -> HomeView.ViewModel {
    HomeView.ViewModel(networkManager: networkManager, modelContext: modelContainer.mainContext)
  }

  @MainActor
  func createSavedViewModel() -> SavedView.ViewModel {
    SavedView.ViewModel(modelContext: modelContainer.mainContext)
  }

  @MainActor
  func createQuizViewModel() -> QuizView.ViewModel {
    QuizView.ViewModel()
  }

  @MainActor
  func createQuoteCollectionCardsViewModel() -> QuoteCollectionCardsViewModel {
    QuoteCollectionCardsViewModel(modelContext: modelContainer.mainContext)
  }

  @MainActor
  func createSaveBottomsheetViewModel(card: Card) -> SaveBottomsheetViewModel {
    SaveBottomsheetViewModel(modelContext: modelContainer.mainContext, card: card)
  }
}
