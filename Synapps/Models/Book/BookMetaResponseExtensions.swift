//
//  BookMetaResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

extension BookMetaResponse {
  convenience init(dto: BookMetaResponseDTO) {
    self.init(id: dto.id, title: dto.title, editionNumber: dto.editionNumber, year: dto.year, publisher: dto.publisher, authors: dto.authors, genres: dto.genres)
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
