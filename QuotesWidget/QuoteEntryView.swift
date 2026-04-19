import AppIntents
import SwiftUI
import WidgetKit

struct QuoteEntryView: View {
  @Environment(\.widgetFamily) private var widgetFamily
  var entry: QuoteEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if widgetFamily != .systemSmall, let cardType = entry.cardType {
        typeBadge(cardType)
          .padding(.bottom, 10)
      }

      Text(entry.isPlaceholder ? "" : entry.quoteText)
        .font(.system(size: 15, weight: .medium, design: .serif))
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.85)
        .lineLimit(widgetFamily == .systemLarge ? 14 : 6)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(widgetFamily == .systemSmall ? 12 : 16)
    .widgetURL(entry.destinationURL)
    .containerBackground(for: .widget) {
      iridescentBackground
    }
  }

  private func typeBadge(_ type: CardType) -> some View {
    Text(type.localizedName)
      .font(.caption2)
      .foregroundStyle(CardType.typeColor(for: type))
      .padding(.vertical, 2)
      .padding(.horizontal, 6)
      .background(Capsule().fill(CardType.typeColor(for: type).opacity(0.15)))
  }
}

extension QuoteEntryView {
  @ViewBuilder
  var iridescentBackground: some View {
    let accent = CardType.typeColor(for: entry.cardType)
    ZStack {
      LinearGradient(
        colors: [accent.opacity(0.55), accent.opacity(0.15)],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
      )
      LinearGradient(
        colors: [.white.opacity(0.8), .white.opacity(0.5), .clear],
        startPoint: .topLeading,
        endPoint: UnitPoint(x: 0.6, y: 0.6)
      )
    }
  }
}

#Preview("Small – Thesis", as: .systemSmall) {
  QuoteWidgetExtension()
} timeline: {
  QuoteEntry(date: .now, quoteText: "Это наши выборы определяют, кто мы есть, а не наши способности.", cardType: .thesis, collectionId: "qc-morning", isPlaceholder: false)
}

#Preview("Medium – Idea", as: .systemMedium) {
  QuoteWidgetExtension()
} timeline: {
  QuoteEntry(date: .now, quoteText: "Первые минуты после пробуждения задают настрой: не телефон, а одна строка в дневнике.", cardType: .idea, collectionId: "qc-morning", isPlaceholder: false)
}

#Preview("Placeholder", as: .systemSmall) {
  QuoteWidgetExtension()
} timeline: {
  QuoteEntry(date: .now, quoteText: "", cardType: nil, collectionId: nil, isPlaceholder: true)
}
