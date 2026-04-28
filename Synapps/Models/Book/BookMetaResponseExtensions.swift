//
//  BookMetaResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

extension BookMetaResponse {
  convenience init(dto: BookMetaResponseDTO) {
    self.init(
      id: dto.id ?? UUID().uuidString,
      title: dto.title,
      editionNumber: dto.editionNumber ?? 0,
      year: dto.year ?? 0,
      publisher: dto.publisher,
      authors: dto.authors.map {
        "\($0.firstName) \($0.lastName)"
      },
      genres: dto.genres.map(\.name),
      coverImageUrl: dto.coverUrl.flatMap { URL(string: Constants.serverURL + $0) }
    )
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
      authors: ["Mock Author"],
      genres: ["Fantasy"],
      coverImageUrl: coverUrl
    )
  }

  static func mockForScreenshot() -> [BookMetaResponse] {
    [
      BookMetaResponse(
        id: UUID().uuidString,
        title: "Психология влияния",
        editionNumber: 0,
        year: 2024,
        publisher: "Pifagor",
        authors: ["Роберт Чалдини"],
        genres: ["Fantasy"],
        coverImageUrl: URL(string: "https://cdn.litres.ru/pub/c/cover_415/6994167.webp")!
      ),
      BookMetaResponse(
        id: UUID().uuidString,
        title: "Гарри Поттер и Узник Аскабана",
        editionNumber: 0,
        year: 2003,
        publisher: "Pifagor",
        authors: ["Дж. К. Ролинг"],
        genres: ["Fantasy"],
        coverImageUrl: URL(string: "https://avatars.mds.yandex.net/get-mpic/5238069/img_id7344419894101235815.jpeg/orig")!
      ),
    ]
  }

  static func mockWithoutURL() -> BookMetaResponse {
    BookMetaResponse(
      id: UUID().uuidString,
      title: "Mock Book",
      editionNumber: 0,
      year: 2000,
      publisher: "Pifagor",
      authors: ["Mock Author"],
      genres: ["Fantasy"],
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
      authors: ["Mock Author"],
      genres: ["Fantasy"],
      coverImageUrl: coverUrl
    )
  }
}
#endif
