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
  static func mocks() -> [QuoteCollection] {
    [
      QuoteCollection(
        id: "qc-morning",
        title: "Утреннее чтение",
        cardIds: ["c-1", "c-2", "c-3", "c-4", "c-5", "c-6", "c-7", "c-8", "c-9", "c-10"]
      ),
      QuoteCollection(
        id: "qc-work",
        title: "Идеи для работы",
        cardIds: ["c-11", "c-12", "c-13", "c-14", "c-15"]
      ),
      QuoteCollection(
        id: "qc-empty",
        title: "Без названия",
        cardIds: []
      ),
      QuoteCollection(
        id: "qc-favorites",
        title: "Избранное из «Гарри Поттера»",
        cardIds: ["c26b27dc-ef2e-46f9-823f-77afa820c202", "b17b18cc-ef3d-46f9-823f-99afa830c101", "f8f4b3cc-ef8d-46f9-823f-89afae30c91a"]
      ),
    ]
  }

  static func mock() -> QuoteCollection {
    mocks().first { $0.id == "qc-morning" }!
  }
}
