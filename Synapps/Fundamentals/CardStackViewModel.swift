import SwiftUI

/// Shared contract for screens that show a `CardSwiperView` with a gradient background driven by card type.
protocol CardStackViewModel: ObservableObject {
  associatedtype Item
  var items: [Item] { get set }
  var topCardIndex: Int { get set }
  var viewId: UUID { get }
  func cardType(for item: Item) -> CardType?
  func fetch()
}

extension CardStackViewModel {
  /// Type of the currently visible card, used for background gradient.
  var topCardTypeForBackground: CardType? {
    guard topCardIndex >= 0, topCardIndex < items.count else { return nil }
    return cardType(for: items[topCardIndex])
  }
    
    var currentCardIndex: Int {
        guard topCardIndex >= 0, topCardIndex < items.count else { return 0 }
        return items.count - topCardIndex - 1
    }
}
