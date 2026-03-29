import SwiftUI

struct QuizDestination: Hashable {}

struct QuizView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    CardStackView(
      viewModel: viewModel,
      onCardSwiped: { swipeDirection, index in
        switch swipeDirection {
        case .left:
          print("Quiz card swiped left at index \(index)")
        case .right:
          print("Quiz card swiped right at index \(index)")
        case .undefined:
          break
        }
      },
      content: { flashCard in
        FlipCardView(flashCard: flashCard)
      }
    )
  }
}

#if DEBUG
#Preview {
  QuizView(viewModel: QuizView.ViewModel())
    .ignoresSafeArea()
}
#endif
