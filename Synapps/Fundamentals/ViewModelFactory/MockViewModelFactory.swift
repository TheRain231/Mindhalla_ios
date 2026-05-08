//
//  MockViewModelFactory.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import Foundation
import SwiftData
import SwiftUI

#if DEBUG
final class MockViewModelFactory: ViewModelFactoryProtocol {
  let networkManager: NetworkManagerProtocol = MockNetworkManager()
  let embeddingService: EmbeddingService = MockEmbeddingService()

  @MainActor
  private(set) lazy var autoTagScheduler: AutoTagScheduler = {
    let clustering = CardClusteringService(modelContext: modelContainer.mainContext, embeddingService: embeddingService)
    let service = AutoTaggingService(modelContext: modelContainer.mainContext, clusteringService: clustering)
    return AutoTagScheduler(service: service)
  }()
  @MainActor // для mainContext
  let modelContainer: ModelContainer = {
    let schema = Schema([
      BookByIdResponse.self,
      BookMetaResponse.self,
      QuoteCollection.self,
      Card.self,
      BookTasksResponse.self,
      BookTask.self,
      BookTaskOption.self,
    ])
    let cfg = ModelConfiguration(
      for: BookByIdResponse.self,
      BookMetaResponse.self,
      QuoteCollection.self,
      Card.self,
      BookTasksResponse.self,
      BookTask.self,
      BookTaskOption.self,
      isStoredInMemoryOnly: true
    )

    let container = try! ModelContainer(for: schema, configurations: [cfg])

    for _ in 0..<10 {
      container.mainContext.insert(BookMetaResponse.mock())
    }
    for card in Card.mocks() {
      container.mainContext.insert(card)
    }
    for collection in QuoteCollection.mocks() {
      container.mainContext.insert(collection)
    }

    return container
  }()

  @MainActor
  func createContentViewModel() -> ContentView.ViewModel {
    ContentView.ViewModel()
  }

  @MainActor
  func createCardsViewModel(cardID: String, prefetchedBook: BookByIdResponse? = nil) -> CardsView.ViewModel {
    CardsView.ViewModel(cardID: cardID, networkManager: networkManager, modelContext: modelContainer.mainContext, prefetchedBook: prefetchedBook, autoTagScheduler: autoTagScheduler)
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
  func createBookTasksViewModel(bookId: String, prefetchedTasks: BookTasksResponse? = nil) -> BookTasksView.ViewModel {
    BookTasksView.ViewModel(
      bookId: bookId,
      networkManager: networkManager,
      modelContext: modelContainer.mainContext,
      prefetchedTasks: prefetchedTasks
    )
  }

  @MainActor
  func createQuoteCollectionCardsViewModel() -> QuoteCollectionCardsViewModel {
    QuoteCollectionCardsViewModel(modelContext: modelContainer.mainContext)
  }

  @MainActor
  func createSaveBottomsheetViewModel(card: Card) -> SaveBottomsheetViewModel {
    SaveBottomsheetViewModel(modelContext: modelContainer.mainContext, card: card, autoTagScheduler: autoTagScheduler)
  }

  @MainActor
  func createCardClusteringService() -> CardClusteringService {
    CardClusteringService(modelContext: modelContainer.mainContext, embeddingService: embeddingService)
  }
}
#endif
