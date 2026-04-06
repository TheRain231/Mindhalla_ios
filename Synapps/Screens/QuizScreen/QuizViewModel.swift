import SwiftUI

extension QuizView {
  final class ViewModel: ObservableObject {
    @Published var flashCards: [FlashCard] = []
    @Published var topCardIndex: Int = 0
    @Published var viewId = UUID()

    func fetch() {
      #if DEBUG
      flashCards = FlashCard.mocks()
      topCardIndex = flashCards.count - 1
      #endif
    }
  }
}

extension QuizView.ViewModel: CardStackViewModel {
  var items: [FlashCard] {
    get { flashCards }
    set { flashCards = newValue }
  }

  func cardType(for item: FlashCard) -> CardType? {
    item.type
  }
}
