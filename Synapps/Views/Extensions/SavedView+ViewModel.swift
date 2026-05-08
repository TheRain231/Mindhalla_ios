//
//  SavedView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 25.12.2025.
//

import SwiftData
import SwiftUI
import WidgetKit

extension SavedView {
  final class ViewModel: ObservableObject {
    let modelContext: ModelContext
    @Published var pickerState: PickerState = .collections
    @Published var collectionSearchText: String = ""
    @Published var cardSearchText: String = ""
    @Published var selectedTypeFilter: CardType?
    @Published var selectedAutoTag: String?
    @Published var sortFilter: SortFilter = .byDate
    @Published var bookIdFilter: String? = nil

    init(modelContext: ModelContext) {
      self.modelContext = modelContext
    }

    func filteredCollections(from collections: [QuoteCollection]) -> [QuoteCollection] {
      let query = collectionSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !query.isEmpty else { return collections }

      let needle = query.lowercased()
      return collections.filter { collection in
        collection.title.lowercased().contains(needle)
      }
    }

    func filteredCards(from cards: [Card]) -> [Card] {
      var result = cards

      if let bookId = bookIdFilter {
        result = result.filter { $0.bookId == bookId }
      }

      if let type = selectedTypeFilter {
        result = result.filter { $0.type == type }
      }

      if let autoTag = selectedAutoTag {
        result = result.filter { card in
          card.tags.contains { $0.type == AutoTaggingService.autoTagType && $0.name == autoTag }
        }
      }

      let query = cardSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
      if !query.isEmpty {
        let needle = query.lowercased()
        result = result.filter { Self.matchesSearch($0, needle: needle) }
      }

      switch sortFilter {
      case .byDate:
        result = result.sorted { ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
      case .alphabetically:
        result = result.sorted { $0.content.localizedCompare($1.content) == .orderedAscending }
      case .byBook:
        result = result.sorted { ($0.bookId ?? "") < ($1.bookId ?? "") }
      }

      return result
    }

    func presentTypes(from cards: [Card]) -> [CardType] {
      let source = bookIdFilter == nil ? cards : cards.filter { $0.bookId == bookIdFilter }
      let present = Set(source.map(\.type))
      return CardType.allCases.filter { present.contains($0) }
    }

    func presentAutoTags(from cards: [Card]) -> [String] {
      let source = bookIdFilter == nil ? cards : cards.filter { $0.bookId == bookIdFilter }
      var counts: [String: Int] = [:]
      for card in source {
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
      }
    }

    func toggleAutoTag(_ name: String) {
      if selectedAutoTag == name {
        selectedAutoTag = nil
      } else {
        selectedAutoTag = name
      }
    }

    func toggleSortFilter(_ filter: SortFilter) {
      sortFilter = filter
      selectedTypeFilter = nil
    }

    func clearBookFilter() {
      bookIdFilter = nil
      selectedTypeFilter = nil
      selectedAutoTag = nil
    }

    func deleteCard(_ card: Card, allCards: [Card]) {
      let cardId = card.id
      let collections = (try? modelContext.fetch(FetchDescriptor<QuoteCollection>())) ?? []
      for collection in collections where collection.cardIds.contains(cardId) {
        collection.cardIds.removeAll { $0 == cardId }
      }

      modelContext.delete(card)
      try? modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()

      if let selectedTypeFilter,
         !presentTypes(from: allCards.filter { $0.id != cardId }).contains(selectedTypeFilter) {
        self.selectedTypeFilter = nil
      }
      if let selectedAutoTag,
         !presentAutoTags(from: allCards.filter { $0.id != cardId }).contains(selectedAutoTag) {
        self.selectedAutoTag = nil
      }
    }

    func createCollection(title: String) {
      let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return }
      let collection = QuoteCollection(title: trimmed)
      modelContext.insert(collection)
      try? modelContext.save()
      WidgetCenter.shared.reloadAllTimelines()
    }

    func shareText(for card: Card) -> String {
      let referenceText = card.references.originalTexts.joined(separator: "\n")
      if referenceText.isEmpty {
        return card.content
      } else {
        return "\(card.content)\n\n\(referenceText)"
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
}
