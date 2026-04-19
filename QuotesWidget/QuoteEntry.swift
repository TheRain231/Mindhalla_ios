import WidgetKit

struct QuoteEntry: TimelineEntry {
  let date: Date
  let quoteText: String
  let cardType: CardType?
  let collectionId: String?
  let isPlaceholder: Bool

  var destinationURL: URL {
    if let id = collectionId {
      URL(string: "synapps://collection/\(id)")!
    } else {
      URL(string: "synapps://saved")!
    }
  }
}
