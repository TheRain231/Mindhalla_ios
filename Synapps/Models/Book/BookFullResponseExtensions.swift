//
//  BookFullResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation

extension BookFullResponse {
  init(dto: BookFullResponseDTO) {
    self.id = dto.id
    self.title = dto.title
    self.editionNumber = dto.editionNumber
    self.year = dto.year
    self.publisher = dto.publisher
    self.language = dto.language
    self.pages = dto.pages

    self.cards = dto.cards.map { Card(dto: $0) }

    self.authorsBooks = dto.authorsBooks.map { "\($0.firstName) \($0.lastName)" }
    self.genresBooks = dto.genresBooks.map(\.name)
  }
}
