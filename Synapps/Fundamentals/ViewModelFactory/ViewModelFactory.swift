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
    let client = Client(service: apiService)
    networkManager = NetworkManager(client: client)
    modelContainer = {
      let schema = Schema([BookFullResponse.self, BookMetaResponse.self, Card.self, QuoteCollection.self])
      let cfg = ModelConfiguration(for: BookFullResponse.self, BookMetaResponse.self, Card.self, QuoteCollection.self)

      #if DEBUG
      print("Located at \(cfg.url.path(percentEncoded: false))")
      #endif

      do {
        return try ModelContainer(for: schema, configurations: [cfg])
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
  func createSaveBottomsheetViewModel() -> SaveBottomsheetViewModel {
    SaveBottomsheetViewModel(modelContext: modelContainer.mainContext)
  }
}
