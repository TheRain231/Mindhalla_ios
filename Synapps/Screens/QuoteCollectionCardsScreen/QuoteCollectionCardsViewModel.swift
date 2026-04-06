import SwiftData
import SwiftUI

@MainActor @Observable
final class QuoteCollectionCardsViewModel {
  let modelContext: ModelContext
  var cards: [Card] = []

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func fetchCards(for _: [String]) {
//        let ids = cardIds
//        let predicate = #Predicate<Card> { card in
//            ids.contains(card.id)
//        }
//        let descriptor = FetchDescriptor<Card>(predicate: predicate)
//        cards = (try? modelContext.fetch(descriptor)) ?? []
  }
}
