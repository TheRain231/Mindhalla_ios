//
//  BookExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

#if DEBUG
extension BookSummary {
  static func mock() -> BookSummary {
    let coverUrl = URL(string: "https://main-cdn.sbermegamarket.ru/hlr-system/131/227/639/991/113/50/600002347616b0.jpeg")!
    return BookSummary(
      id: UUID().uuidString,
      title: "Mock Book",
      editionNumber: 0,
      year: 2000,
      publisher: "Pifagor",
      authors: "Mock Author",
      genres: "Fantasy",
      coverImageUrl: coverUrl
    )
  }

  static func mockWithoutURL() -> BookSummary {
    BookSummary(
      id: UUID().uuidString,
      title: "Mock Book",
      editionNumber: 0,
      year: 2000,
      publisher: "Pifagor",
      authors: "Mock Author",
      genres: "Fantasy",
      coverImageUrl: nil
    )
  }

  static func mockWithURLError() -> BookSummary {
    let coverUrl: URL? = URL(string: "https:tutcartinkinet.ry/cartinka.jpeg")!
    return BookSummary(
      id: UUID().uuidString,
      title: "Mock Book",
      editionNumber: 0,
      year: 2000,
      publisher: "Pifagor",
      authors: "Mock Author",
      genres: "Fantasy",
      coverImageUrl: coverUrl
    )
  }
}
#endif
