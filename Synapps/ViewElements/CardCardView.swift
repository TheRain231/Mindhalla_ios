//
//  CardCardView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct CardCardView: View {
  let card: Card

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      cardBadge
        .padding(.bottom, 16)
      cardText
        .padding(.bottom, 28)
      cardSource
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(24)
    .background {
      RoundedRectangle(cornerRadius: 32)
        .fill(Color(.systemBackground))
        .cardShadow()
    }
  }

  @ViewBuilder
  private var cardSource: some View {
    if let chapter = card.sourceDescription() {
      Text(chapter)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var cardText: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(card.content)
        .font(.title2)
    }
  }

  private var cardBadge: some View {
    let typeColor = Card.color(for: card.type)
    let autoTags = card.tags.filter { $0.type == AutoTaggingService.autoTagType }
    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        Text(card.type.localizedName)
          .foregroundStyle(Color(.systemBackground))
          .padding(4)
          .padding(.horizontal, 10)
          .background { Capsule().fill(typeColor) }
        ForEach(autoTags, id: \.id) { tag in
          HStack(spacing: 4) {
            Image(systemName: "sparkles")
            Text(tag.name)
          }
          .foregroundStyle(MindMapPalette.primary)
          .padding(4)
          .padding(.horizontal, 10)
          .background { Capsule().fill(MindMapPalette.primary.opacity(0.18)) }
        }
      }
    }
  }
}

#if DEBUG
#Preview("Thesis") {
  CardCardView(card: Card.mockThesis())
}

#Preview("Concept") {
  CardCardView(card: Card.mockConcept())
}

#Preview("Quote") {
  CardCardView(card: Card.mockQuote())
}
#endif
