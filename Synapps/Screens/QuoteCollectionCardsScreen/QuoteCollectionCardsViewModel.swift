import SwiftData
import SwiftUI

@MainActor @Observable
final class QuoteCollectionCardsViewModel {
  let modelContext: ModelContext
  var searchText = ""
  var showRemovalConfirmation: Bool = false
  var showDeleteCollectionConfirmation: Bool = false
  var cardIdPendingRemoval: String?

  /// Все карточки подборки после загрузки (без фильтра поиска).
  var cards: [Card] = []

  /// `nil` — показывать все типы; иначе только выбранный.
  var selectedTypeFilter: CardType?

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  /// Карточки с учётом фильтра по типу и строки поиска.
  var filteredCards: [Card] {
    var result = cards
    if let type = selectedTypeFilter {
      result = result.filter { $0.type == type }
    }

    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return result }
    let needle = query.lowercased()
    return result.filter { Self.matchesSearch($0, needle: needle) }
  }

  var presentTypes: [CardType] {
    let present = Set(cards.map(\.type))
    return CardType.allCases.filter { present.contains($0) }
  }

  func toggleTypeFilter(_ type: CardType) {
    if selectedTypeFilter == type {
      selectedTypeFilter = nil
    } else {
      selectedTypeFilter = type
    }
  }

  private static func matchesSearch(_ card: Card, needle: String) -> Bool {
    var parts: [String] = [
      card.content,
      card.type.rawValue,
      String(localized: String.LocalizationValue(card.type.localized)),
    ]
    for tag in card.tags {
      parts.append(tag.name)
      parts.append(tag.description)
    }
    for text in card.references.originalTexts {
      parts.append(text)
    }
    return parts.contains { $0.lowercased().contains(needle) }
  }
}

// MARK: - SwiftData

extension QuoteCollectionCardsViewModel {
  /// Загрузка карточек
  func fetchCards(for cardIds: [String]) {
    let ids = cardIds
    let predicate = #Predicate<Card> { card in
      ids.contains(card.id)
    }
    let descriptor = FetchDescriptor<Card>(predicate: predicate)
    cards = (try? modelContext.fetch(descriptor)) ?? []
    selectedTypeFilter = nil
  }

  /// Удаление карточки из текущей подборки с обновлением списка на экране.
  func removeCardFromCollection(cardId: String, collectionId: String) {
    let cid = collectionId
    let predicate = #Predicate<QuoteCollection> { $0.id == cid }
    var descriptor = FetchDescriptor<QuoteCollection>(predicate: predicate)
    descriptor.fetchLimit = 1
    guard let collection = try? modelContext.fetch(descriptor).first else { return }
    collection.cardIds.removeAll { $0 == cardId }
    try? modelContext.save()

    withAnimation(.linear(duration: 0.5)) {
      cards.removeAll { $0.id == cardId }

      if let selected = selectedTypeFilter, !presentTypes.contains(selected) {
        selectedTypeFilter = nil
      }
    }
  }

  /// Удаление коллекции.
  func delete(_ collection: QuoteCollection) {
    modelContext.delete(collection)
    try? modelContext.save()
  }
}
