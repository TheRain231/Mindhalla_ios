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

  private var cardSource: some View {
    Text(card.sourceDescription())
      .font(.caption)
      .foregroundStyle(.secondary)
  }

  private var cardText: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(card.context)
        .font(.title2)
    }
  }

  private var cardBadge: some View {
    let title = switch card.type {
    case .thesis:
      "Тезис"
    case .concept:
      "Концепция"
    case .idea:
      "Цитата"
    case .question:
      "Вопрос"
    case .answer:
      "Ответ"
    case .unknown:
      "Неизвестный"
    }

    return Text(title)
      .foregroundStyle(Color(.systemBackground))
      .padding(4)
      .padding(.horizontal, 10)
      .background {
        Capsule()
          .fill(Card.color(for: card.type))
      }
  }
}

#Preview("Thesis") {
  CardCardView(card: Card.mockThesis())
}

#Preview("Concept") {
  CardCardView(card: Card.mockConcept())
}

#Preview("Quote") {
  CardCardView(card: Card.mockQuote())
}
