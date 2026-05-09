//
//  CardCardView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct CardCardView: View {
  let card: Card
  var showsAutoTags: Bool = true

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
    let autoTags = showsAutoTags ? card.tags.filter { $0.type == AutoTaggingService.autoTagType } : []
    return WrapHStack(spacing: 8, lineSpacing: 6) {
      Text(card.type.localizedName)
        .foregroundStyle(Color(.systemBackground))
        .padding(4)
        .padding(.horizontal, 10)
        .background { Capsule().fill(typeColor) }
      ForEach(autoTags, id: \.id) { tag in
        HStack(spacing: 4) {
          Image(systemName: "sparkles")
          Text(tag.name).lineLimit(1)
        }
        .foregroundStyle(MindMapPalette.primary)
        .padding(4)
        .padding(.horizontal, 10)
        .background { Capsule().fill(MindMapPalette.primary.opacity(0.18)) }
      }
    }
  }
}

private struct WrapHStack: Layout {
  var spacing: CGFloat
  var lineSpacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    var rowWidth: CGFloat = 0
    var rowHeight: CGFloat = 0
    var totalHeight: CGFloat = 0
    var totalWidth: CGFloat = 0
    for sub in subviews {
      let size = sub.sizeThatFits(.unspecified)
      let needed = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
      if needed > maxWidth, rowWidth > 0 {
        totalHeight += rowHeight + lineSpacing
        totalWidth = max(totalWidth, rowWidth)
        rowWidth = size.width
        rowHeight = size.height
      } else {
        rowWidth = needed
        rowHeight = max(rowHeight, size.height)
      }
    }
    totalHeight += rowHeight
    totalWidth = max(totalWidth, rowWidth)
    return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let maxWidth = bounds.width
    var x: CGFloat = bounds.minX
    var y: CGFloat = bounds.minY
    var rowHeight: CGFloat = 0
    for sub in subviews {
      let size = sub.sizeThatFits(.unspecified)
      if x > bounds.minX, x - bounds.minX + size.width > maxWidth {
        x = bounds.minX
        y += rowHeight + lineSpacing
        rowHeight = 0
      }
      sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
      x += size.width + spacing
      rowHeight = max(rowHeight, size.height)
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
