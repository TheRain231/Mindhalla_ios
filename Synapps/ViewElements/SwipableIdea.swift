//
//  SwipableIdea.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct SwipableIdea: View {
  let idea: Idea

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ideaBadge
        .padding(.bottom, 16)
      ideaText
        .padding(.bottom, 28)
      ideaSource
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(24)
    .background {
      RoundedRectangle(cornerRadius: 32)
        .fill(Color(.systemBackground))
        .cardShadow()
    }
  }

  private var ideaSource: some View {
    Text(idea.sourceDescription())
      .font(.caption)
      .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private var ideaText: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(idea.text)

      if let author = idea.author {
        Text("© \(author)")
          .foregroundStyle(.secondary)
      }
    }
    .font(.title2)
  }

  private var ideaBadge: some View {
    let title = switch idea.type {
    case .Thesis:
      "Тезис"
    case .Concept:
      "Концепция"
    case .Quote:
      "Цитата"
    }

    return Text(title)
      .foregroundStyle(Color(.systemBackground))
      .padding(4)
      .padding(.horizontal, 10)
      .background {
        Capsule()
          .fill(Idea.color(for: idea.type))
      }
  }
}

#Preview("Thesis") {
  SwipableIdea(idea: Idea.mockThesis())
}

#Preview("Concept") {
  SwipableIdea(idea: Idea.mockConcept())
}

#Preview("Quote") {
  SwipableIdea(idea: Idea.mockQuote())
}
