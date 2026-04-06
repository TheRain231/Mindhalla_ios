import SwiftUI

struct FlipCardView: View {
  let flashCard: FlashCard
  @State private var isFlipped = false

  var body: some View {
    ZStack {
      cardFront
        .opacity(isFlipped ? 0 : 1)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

      cardBack
        .opacity(isFlipped ? 1 : 0)
        .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
    }
    .onTapGesture {
      withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
        isFlipped.toggle()
      }
    }
  }

  private var cardFront: some View {
    CardCardView(card: flashCard.questionCard)
  }

  private var cardBack: some View {
    CardCardView(card: flashCard.answerCard)
  }
}

extension FlashCard {
  fileprivate var questionCard: Card {
    Card(
      id: id + "-q",
      type: .question,
      content: question,
      references: References(pages: [], originalTexts: []),
      tags: []
    )
  }

  fileprivate var answerCard: Card {
    Card(
      id: id + "-a",
      type: .answer,
      content: answer,
      references: References(pages: [], originalTexts: []),
      tags: []
    )
  }
}

#if DEBUG
#Preview("Front") {
  FlipCardView(flashCard: FlashCard.mocks()[0])
    .frame(width: 320, height: 420)
    .padding()
}
#endif
