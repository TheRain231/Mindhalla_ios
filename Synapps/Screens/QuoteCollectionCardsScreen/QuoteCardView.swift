import SwiftUI

struct QuoteCardView: View {
  let quote: String
  let author: String
  let source: String
  let type: CardType

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      typeAccentBar
        .padding(.top, 16)

      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 8) {
          Text(quote)
            .font(.system(size: 16))
          Spacer()
          Button {
            // action
          } label: {
            Image(systemName: "ellipsis")
          }
          .foregroundStyle(.primary)
          .padding()
        }
        .padding(.bottom, 10)
        sourceView
      }
      .padding()
    }
    .background {
      RoundedRectangle(cornerRadius: 16)
        .foregroundStyle(.white)
    }
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
  }
}

extension QuoteCardView {
  private var typeAccentBar: some View {
    UnevenRoundedRectangle(
      cornerRadii: RectangleCornerRadii(
        topLeading: 0,
        bottomLeading: 0,
        bottomTrailing: 4,
        topTrailing: 4
      ),
      style: .continuous
    )
    .fill(CardType.typeColor(for: type))
    .frame(width: 6, height: 16)
  }

  private var sourceView: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: "c.circle")
        Text(author)
          .font(.system(size: 15))
      }
      Text(source)
        .font(.system(size: 12, weight: .regular))
    }
    .foregroundStyle(.secondary)
  }
}

#Preview {
  QuoteCardView(
    quote: "Знание — это не количество информации, а умение правильно применять её в жизни и делать осознанные выводы.",
    author: "Илон Маск",
    source: "Почему экзетенциализм не всегда стоит анализировать",
    type: .thesis
  )
}
