//
//  BookOverview.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct BookOverview: View {
  let book: BookMetaResponse
  var onRetry: (() -> Void)? = nil

  var body: some View {
    VStack(alignment: .leading) {
      header
      titleView
      authorView
      savedIdeasView
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
      progressText
    }
  }

  private var titleView: some View {
    Text(book.title)
      .font(.system(size: 40, weight: .semibold))
  }

  private var authorView: some View {
    Group {
      if book.isProcessing {
        Text("BookProcessing.Status.InProgress")
      } else if book.hasFailed {
        Text("BookProcessing.Status.Failed")
      } else {
        Text(book.authors.joined(separator: ", "))
      }
    }
    .font(.system(size: 20))
    .foregroundStyle(.secondary)
  }

  private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 24)
      .fill(Color(.systemBackground))
  }

  @ViewBuilder
  private var savedIdeasView: some View {
    if book.savedIdeasCount > 0 {
      Label("\(book.savedIdeasCount) сохраненных", systemImage: "bookmark")
        .labelStyle(TextBadgeLabelStyle())
    }
  }

  @ViewBuilder
  private var progressText: some View {
    if book.isProcessing {
      let pct = book.processingPercentage
      VStack(alignment: .trailing, spacing: 2) {
        if pct > 0 {
          Text("\(pct)%")
            .font(.system(size: 16, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color(hex: "9B60E9"))
        } else {
          ProgressView()
            .scaleEffect(0.8)
        }
      }
      .padding(8)
    } else if book.hasFailed {
      Button { onRetry?() } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .padding(10)
          .background(Color(hex: "9B60E9"), in: Circle())
      }
      .buttonStyle(.plain)
    } else if book.percentageRead > 0 {
      Text("\(Int(ceil(book.percentageRead)))% • Еще \(timeToReadText)")
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(8)
    }
  }

  // MARK: - Cover

  @ViewBuilder
  private var coverImage: some View {
    if book.isProcessing {
      ShimmerView()
        .clipShape(RoundedRectangle(cornerRadius: 8))
    } else if book.hasFailed {
      ZStack {
        Color(.systemGray5)
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 36))
          .foregroundStyle(.secondary)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
    } else if let cover = book.coverImageUrl {
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

  private var timeToReadText: String {
    let minutes = book.timeToRead / 60.0
    if minutes > 60 {
      let hours = Int(ceil(minutes / 60.0))
      return "\(hours) ч"
    } else {
      let mins = Int(ceil(minutes))
      return "\(mins) мин"
    }
  }
}

// MARK: - Shimmer

private struct ShimmerView: View {
  @State private var phase: CGFloat = -1

  var body: some View {
    GeometryReader { geo in
      LinearGradient(
        stops: [
          .init(color: Color(.systemGray5), location: 0),
          .init(color: Color(.systemGray4), location: 0.4),
          .init(color: Color(.systemGray5), location: 0.8),
        ],
        startPoint: .init(x: phase, y: 0),
        endPoint: .init(x: phase + 1, y: 0)
      )
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .onAppear {
      withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
        phase = 1
      }
    }
  }
}

// MARK: - TextBadgeLabelStyle

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

#Preview("Processing") {
  let book = BookMetaResponse(id: "1", title: "d-20-21.pdf", editionNumber: 0, year: 0, publisher: nil, authors: [], genres: [], processingStatus: "in_progress")
  BookOverview(book: book)
    .padding()
}

#Preview("Failed") {
  let book = BookMetaResponse(id: "2", title: "d-20-21.pdf", editionNumber: 0, year: 0, publisher: nil, authors: [], genres: [], processingStatus: "failed")
  BookOverview(book: book, onRetry: {})
    .padding()
}
