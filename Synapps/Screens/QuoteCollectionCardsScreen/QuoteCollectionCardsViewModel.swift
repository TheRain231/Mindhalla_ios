import SwiftData
import SwiftUI
import WidgetKit

enum CollectionSortFilter: CaseIterable, Identifiable {
  case byDate
  case alphabetically

  var id: Self { self }

  var localizedTitle: LocalizedStringKey {
    switch self {
    case .byDate: "SavedView.Sort.ByDate"
    case .alphabetically: "SavedView.Sort.Alphabetically"
    }
  }
}

@MainActor @Observable
final class QuoteCollectionCardsViewModel {
  let modelContext: ModelContext
  var searchText = ""
  var showRemovalConfirmation: Bool = false
  var showDeleteCollectionConfirmation: Bool = false
  var cardIdPendingRemoval: String?
  var sortFilter: CollectionSortFilter = .byDate

  /// Все карточки подборки после загрузки (без фильтра поиска).
  var cards: [Card] = []

  /// `nil` — показывать все типы; иначе только выбранный.
  var selectedTypeFilter: CardType?

  /// Активный авто-тег (имя). Применяется поверх типа и поиска.
  var selectedAutoTag: String?

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  /// Карточки с учётом фильтра по типу, сортировки и строки поиска.
  var filteredCards: [Card] {
    var result = cards
    if let type = selectedTypeFilter {
      result = result.filter { $0.type == type }
    }

    if let autoTag = selectedAutoTag {
      result = result.filter { card in
        card.tags.contains { $0.type == AutoTaggingService.autoTagType && $0.name == autoTag }
      }
    }

    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if !query.isEmpty {
      let needle = query.lowercased()
      result = result.filter { Self.matchesSearch($0, needle: needle) }
    }

    switch sortFilter {
    case .byDate:
      result = result.sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
    case .alphabetically:
      result = result.sorted { $0.content.localizedCompare($1.content) == .orderedAscending }
    }

    return result
  }

  var presentTypes: [CardType] {
    let present = Set(cards.map(\.type))
    return CardType.allCases.filter { present.contains($0) }
  }

  var presentAutoTags: [String] {
    var counts: [String: Int] = [:]
    for card in cards {
      for tag in card.tags where tag.type == AutoTaggingService.autoTagType {
        counts[tag.name, default: 0] += 1
      }
    }
    return counts.sorted { lhs, rhs in
      lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
    }.prefix(20).map(\.key)
  }

  func toggleTypeFilter(_ type: CardType) {
    if selectedTypeFilter == type {
      selectedTypeFilter = nil
    } else {
      selectedTypeFilter = type
      sortFilter = .byDate
    }
  }

  func toggleAutoTag(_ name: String) {
    if selectedAutoTag == name {
      selectedAutoTag = nil
    } else {
      selectedAutoTag = name
    }
  }

  func toggleSortFilter(_ filter: CollectionSortFilter) {
    sortFilter = filter
    selectedTypeFilter = nil
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
    WidgetCenter.shared.reloadAllTimelines()

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
    WidgetCenter.shared.reloadAllTimelines()
  }
}
