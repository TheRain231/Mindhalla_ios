import Foundation
import SwiftData

@Model
final class QuoteCollection: Identifiable, Hashable {
  var id: String
  var title: String
  /// Идентификаторы карточек, входящих в подборку.
  var cardIds: [String]

  var quoteCount: Int { cardIds.count }

  init(
    id: String = UUID().uuidString,
    title: String,
    cardIds: [String] = []
  ) {
    self.id = id
    self.title = title
    self.cardIds = cardIds
  }
}

extension QuoteCollection {
  static let mocks: [QuoteCollection] = [
    QuoteCollection(
      id: "qc-morning",
      title: "Утреннее чтение",
      cardIds: ["c-1", "c-2", "c-3", "c-4"]
    ),
    QuoteCollection(
      id: "qc-work",
      title: "Идеи для работы",
      cardIds: ["c-10", "c-11", "c-12", "c-13", "c-14", "c-15"]
    ),
    QuoteCollection(
      id: "qc-empty",
      title: "Без названия",
      cardIds: []
    ),
    QuoteCollection(
      id: "qc-favorites",
      title: "Избранное из «Гарри Поттера»",
      cardIds: ["c-101", "c-102", "c-103"]
    ),
  ]

  static let mock: QuoteCollection = .mocks.first!
}
