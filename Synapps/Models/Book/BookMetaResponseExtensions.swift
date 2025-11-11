//
//  BookMetaResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

extension BookMetaResponse {
  init(dto: Components.Schemas.BookMetaResponse) {
    self.id = dto.id
    self.title = dto.title
    self.editionNumber = dto.edition_number
    self.year = dto.year
    self.publisher = dto.publisher
    self.authors = dto.authors
    self.genres = dto.genres

    self.coverImageUrl = nil
  }
}

#if DEBUG
extension BookMetaResponse {
  static func mock() -> BookMetaResponse {
    let coverUrl = URL(string: "https://main-cdn.sbermegamarket.ru/hlr-system/131/227/639/991/113/50/600002347616b0.jpeg")!
    return BookMetaResponse(
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

  static func mockWithoutURL() -> BookMetaResponse {
    BookMetaResponse(
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

  static func mockWithURLError() -> BookMetaResponse {
    let coverUrl: URL? = URL(string: "https:tutcartinkinet.ry/cartinka.jpeg")!
    return BookMetaResponse(
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
