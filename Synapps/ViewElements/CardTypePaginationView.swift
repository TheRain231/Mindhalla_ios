import SwiftUI

struct CardTypePaginationView: View {
  let cardTypes: [CardType]
  let onTap: (CardType) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(cardTypes, id: \.self) { type in
          cardTypeView(type)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }
}

extension CardTypePaginationView {
  private func cardTypeView(_ type: CardType) -> some View {
    Button {
      onTap(type)
    } label: {
      Text(type.localizedName)
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(CardType.typeColor(for: type))
        .clipShape(.capsule)
    }
  }
}
