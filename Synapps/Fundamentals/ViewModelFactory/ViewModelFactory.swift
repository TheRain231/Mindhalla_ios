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
  lazy var embeddingService: EmbeddingService = ONNXEmbeddingService()

  @MainActor
  private(set) lazy var autoTagScheduler: AutoTagScheduler = {
    let clustering = CardClusteringService(modelContext: modelContainer.mainContext, embeddingService: embeddingService)
    let service = AutoTaggingService(modelContext: modelContainer.mainContext, clusteringService: clustering)
    return AutoTagScheduler(service: service)
  }()

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
