//
//  BookOverview.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct BookOverview: View {
  let book: BookMetaResponse

  var body: some View {
    VStack(alignment: .leading) {
      header
      titleView
      authorView
//      savedIdeasView
    }
    .padding()
    .background(cardBackground)
    .cardShadow()
  }

  // MARK: - Composition

  private var header: some View {
    HStack(alignment: .top) {
      coverImage
        .frame(width: 100, height: 160)
      Spacer()
//      progressText
    }
  }

  private var titleView: some View {
    Text(book.title)
      .font(.system(size: 40, weight: .semibold))
  }

  private var authorView: some View {
    Text(book.authors.joined(separator: ", "))
      .font(.system(size: 20))
      .foregroundStyle(.secondary)
  }

//  private var savedIdeasView: some View {
//    Label("\(book.savedIdeasCount) сохраненных", systemImage: "bookmark")
//      .labelStyle(TextBadgeLabelStyle())
//  }

//  private var progressText: some View {
//    Text("\(Int(ceil(book.percentageRead)))% • Еще \(timeToReadText)")
//      .padding()
//  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(Color(.systemBackground))
  }

  // MARK: - Subviews

  @ViewBuilder
  private var coverImage: some View {
    if let cover = book.coverImageUrl {
      AsyncImage(url: cover) { phase in
        if let image = phase.image {
          image
            .resizable()
            .scaledToFit()
        } else if phase.error != nil {
          Image(systemName: "book.closed")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)
        } else {
          ProgressView()
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
    } else {
      ZStack {
        Color.gray.opacity(0.3)
        Image(systemName: "book.closed")
          .font(.system(size: 40))
          .padding()
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }

  // MARK: - Helpers

//  private var timeToReadText: String {
//    let minutes = book.timeToRead / 60.0
//    if minutes > 60 {
//      let hours = Int(ceil(minutes / 60.0))
//      return "\(hours) ч"
//    } else {
//      let mins = Int(ceil(minutes))
//      return "\(mins) мин"
//    }
//  }
}

private struct TextBadgeLabelStyle: LabelStyle {
  var backgroundColor: Color = .secondary.opacity(0.2)
  var cornerRadius: CGFloat = 12
  var horizontalPadding: CGFloat = 0
  var verticalPadding: CGFloat = 14
  var spacing: CGFloat = 6

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: spacing) {
      configuration.icon
        .fontWeight(.bold)
        .foregroundStyle(.secondary)
      configuration.title
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, verticalPadding)
    .background(
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(backgroundColor)
        .frame(maxWidth: .infinity)
    )
  }
}

#Preview("Main") {
  BookOverview(book: BookMetaResponse.mock())
}

#Preview("Without URL") {
  BookOverview(book: BookMetaResponse.mockWithoutURL())
}

#Preview("URL Error") {
  BookOverview(book: BookMetaResponse.mockWithURLError())
}
