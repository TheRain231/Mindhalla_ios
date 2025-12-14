//
//  MockViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

final class MockViewModelFactory: ViewModelFactoryProtocol {
  let networkManager: NetworkManagerProtocol = MockNetworkManager()
  @MainActor // для mainContext
  let modelContainer: ModelContainer = {
    let schema = Schema([BookFullResponse.self, BookMetaResponse.self])
    let cfg = ModelConfiguration(for: BookFullResponse.self, BookMetaResponse.self, isStoredInMemoryOnly: true)

    let container = try! ModelContainer(for: schema, configurations: [cfg])

    for _ in 0..<10 {
      container.mainContext.insert(BookMetaResponse.mock())
    }

    return container
  }()

  @MainActor
  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  @MainActor
  func createCardsViewModel(cardID: String) -> CardsView.ViewModel {
    CardsView.ViewModel(cardID: cardID, networkManager: networkManager)
  }

  @MainActor
  func createHomeViewModel() -> HomeView.ViewModel {
    HomeView.ViewModel(networkManager: networkManager, modelContext: modelContainer.mainContext)
  }
}
