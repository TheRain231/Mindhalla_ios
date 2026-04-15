//
//  SavedView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 25.12.2025.
//

import SwiftData
import SwiftUI

extension SavedView {
  final class ViewModel: ObservableObject {
    let modelContext: ModelContext
    @Published var pickerState: PickerState = .collections
    @Published var collectionSearchText: String = ""
    @Published var cardSearchText: String = ""
    @Published var selectedTypeFilter: CardType?

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
      if let type = selectedTypeFilter {
        result = result.filter { $0.type == type }
      }

      let query = cardSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !query.isEmpty else { return result }

      let needle = query.lowercased()
      return result.filter { Self.matchesSearch($0, needle: needle) }
    }

    func presentTypes(from cards: [Card]) -> [CardType] {
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

    func deleteCard(_ card: Card, allCards: [Card]) {
      let cardId = card.id
      let collections = (try? modelContext.fetch(FetchDescriptor<QuoteCollection>())) ?? []
      for collection in collections where collection.cardIds.contains(cardId) {
        collection.cardIds.removeAll { $0 == cardId }
      }

      modelContext.delete(card)
      try? modelContext.save()

      if let selectedTypeFilter,
         !presentTypes(from: allCards.filter { $0.id != cardId }).contains(selectedTypeFilter) {
        self.selectedTypeFilter = nil
      }
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
