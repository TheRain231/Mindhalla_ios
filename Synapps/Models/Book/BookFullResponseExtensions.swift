//
//  BookFullResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation

extension BookFullResponse {
  convenience init(dto: BookFullResponseDTO) {
    self.init(
      id: dto.id,
      title: dto.title,
      editionNumber: dto.editionNumber,
      year: dto.year,
      publisher: dto.publisher,
      language: dto.language,
      pages: dto.pages,
      cards: dto.cards.map {
        Card(
          dto: $0
        )
      },
      authorsBooks: dto.authorsBooks.map {
        "\($0.firstName) \($0.lastName)"
      },
      genresBooks: dto.genresBooks.map(\.name)
    )
  }
}
