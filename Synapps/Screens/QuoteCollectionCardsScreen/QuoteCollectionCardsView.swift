import SwiftData
import SwiftUI

struct QuoteCollectionCardsView: View {
  @Bindable var viewModel: QuoteCollectionCardsViewModel
  let quoteCollection: QuoteCollection

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
//                ForEach(viewModel.cards) { card in
//                    QuoteCardView(
//                        quote: card.context,
//                        author: card.tags.first?.name ?? "",
//                        source: card.sourceDescription(),
//                        type: card.type
//                    )
//                }
      }
      .padding(.horizontal)
    }
    .onAppear {
      viewModel.fetchCards(for: quoteCollection.cardIds)
    }
    .navigationTitle(quoteCollection.title)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Image(systemName: "ellipsis")
      }
    }
  }
}

#Preview {
  let factory = MockViewModelFactory()

  QuoteCollectionCardsView(viewModel: factory.createQuoteCollectionCardsViewModel(), quoteCollection: QuoteCollection.mock)
}
