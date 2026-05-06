import AppIntents
import SwiftData
import WidgetKit

struct QuoteTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = QuoteEntry
  typealias Intent = QuoteAppIntent
    private let updateInterval: TimeInterval = 60 * 60 * 3

  func placeholder(in _: Context) -> QuoteEntry {
    QuoteEntry(date: Date(), quoteText: "", cardType: nil, collectionId: nil, isPlaceholder: true)
  }

  func snapshot(for configuration: QuoteAppIntent, in _: Context) async -> QuoteEntry {
    let items = loadQuoteItems(collectionId: configuration.collection?.id)
    if let item = items.randomElement() {
      return QuoteEntry(date: Date(), quoteText: item.quoteText, cardType: item.cardType, collectionId: item.collectionId, isPlaceholder: false)
    }
    return QuoteEntry(date: Date(), quoteText: "", cardType: nil, collectionId: nil, isPlaceholder: true)
  }

  func timeline(for configuration: QuoteAppIntent, in _: Context) async -> Timeline<QuoteEntry> {
    let items = loadQuoteItems(collectionId: configuration.collection?.id)

    guard !items.isEmpty else {
      let entry = QuoteEntry(date: Date(), quoteText: "", cardType: nil, collectionId: nil, isPlaceholder: true)
      return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(updateInterval)))
    }

    let shuffled = items.shuffled()
    let now = Date()
    let entries = shuffled.enumerated().map { i, item in
      QuoteEntry(
        date: now.addingTimeInterval(Double(i) * updateInterval),
        quoteText: item.quoteText,
        cardType: item.cardType,
        collectionId: item.collectionId,
        isPlaceholder: false
      )
    }
    return Timeline(entries: entries, policy: .atEnd)
  }

  private struct QuoteItem {
    let quoteText: String
    let cardType: CardType?
    let collectionId: String?
  }

  /// Какую коллекцию подставить в диплинк: выбранная в настройках виджета, иначе единственная, иначе первая по стабильной сортировке.
  private func collectionIdForDeepLink(colIds: [String], preferredCollectionId: String?) -> String? {
    guard !colIds.isEmpty else { return nil }
    if let preferred = preferredCollectionId, colIds.contains(preferred) {
      return preferred
    }
    if colIds.count == 1 {
      return colIds[0]
    }
    return colIds.sorted().first
  }

  private func loadQuoteItems(collectionId: String? = nil) -> [QuoteItem] {
    do {
      let container = try SharedModelStore.makeContainer()
      let context = ModelContext(container)

      var collectionDescriptor = FetchDescriptor<QuoteCollection>()
      if let collectionId {
        collectionDescriptor.predicate = #Predicate { $0.id == collectionId }
      }
      let collections = try context.fetch(collectionDescriptor)
      let cards = try context.fetch(FetchDescriptor<Card>())

      let cardMap = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })

      var cardCollectionIds: [String: [String]] = [:]
      for collection in collections {
        for cardId in collection.cardIds {
          cardCollectionIds[cardId, default: []].append(collection.id)
        }
      }

      return cardCollectionIds.compactMap { cardId, colIds in
        guard let card = cardMap[cardId], !card.content.isEmpty else { return nil }
        let linkCollectionId = collectionIdForDeepLink(colIds: colIds, preferredCollectionId: collectionId)
        return QuoteItem(quoteText: card.content, cardType: card.type, collectionId: linkCollectionId)
      }
    } catch {
      return []
    }
  }

  #if DEBUG
  private func mockItems(collectionId: String? = nil) -> [QuoteItem] {
    let collections = collectionId == nil
      ? QuoteCollection.mocks()
      : QuoteCollection.mocks().filter { $0.id == collectionId }
    let cardMap = Dictionary(uniqueKeysWithValues: Card.mocks().map { ($0.id, $0) })

    var cardCollectionIds: [String: [String]] = [:]
    for collection in collections {
      for cardId in collection.cardIds {
        cardCollectionIds[cardId, default: []].append(collection.id)
      }
    }

    return cardCollectionIds.compactMap { cardId, colIds in
      guard let card = cardMap[cardId], !card.content.isEmpty else { return nil }
      let linkCollectionId = collectionIdForDeepLink(colIds: colIds, preferredCollectionId: collectionId)
      return QuoteItem(quoteText: card.content, cardType: card.type, collectionId: linkCollectionId)
    }
  }
  #endif
}
