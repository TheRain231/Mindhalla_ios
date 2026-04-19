import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor @Observable
final class SaveBottomsheetViewModel {
  let modelContext: ModelContext
  let card: Card
  var searchText: String = ""

  /// Идентификаторы выбранных подборок.
  var selectedIds: Set<String> = []

  init(
    modelContext: ModelContext,
    card: Card
  ) {
    self.modelContext = modelContext
    self.card = card
  }

  /// Подборки, у которых в названии есть введённая подстрока (без учёта регистра).
  func filteredCollections(from collections: [QuoteCollection]) -> [QuoteCollection] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return collections }

    let needle = query.lowercased()
    return collections.filter { $0.title.lowercased().contains(needle) }
  }

  func isSelected(_ collection: QuoteCollection) -> Bool {
    selectedIds.contains(collection.id)
  }

  func toggleSelection(_ collection: QuoteCollection) {
    if selectedIds.contains(collection.id) {
      selectedIds.remove(collection.id)
    } else {
      selectedIds.insert(collection.id)
    }
  }

  func saveCollection(collection: QuoteCollection) {
    let collectionId = collection.id
    let predicate = #Predicate<QuoteCollection> { $0.id == collectionId }
    var descriptor: FetchDescriptor<QuoteCollection> = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1

    if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
      modelContext.insert(collection)
      try? modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  func save() {
    let cardId = card.id
    let predicate = #Predicate<Card> { $0.id == cardId }
    var descriptor: FetchDescriptor<Card> = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1

    if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
      modelContext.insert(card)
    }

    for collectionId in selectedIds {
      let colPredicate = #Predicate<QuoteCollection> { $0.id == collectionId }
      var colDescriptor = FetchDescriptor<QuoteCollection>(predicate: colPredicate)
      colDescriptor.fetchLimit = 1
      if let collections = try? modelContext.fetch(colDescriptor),
         let collection = collections.first,
         !collection.cardIds.contains(card.id) {
        collection.cardIds.append(card.id)
      }
    }
    try? modelContext.save()
    WidgetCenter.shared.reloadAllTimelines()
  }
}
