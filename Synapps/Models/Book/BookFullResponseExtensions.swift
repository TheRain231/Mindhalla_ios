//
//  BookFullResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation

extension BookFullResponse {
  init(dto: Components.Schemas.BookFullResponse) {
    self.id = dto.id
    self.title = dto.title
    self.editionNumber = dto.edition_number
    self.year = dto.year
    self.publisher = dto.publisher
    self.language = dto.language
    self.pages = dto.pages

    self.cards = dto.cards.map { Card(dto: $0) }

    self.authorsBooks = dto.authors_books.map { "\($0.first_name) \($0.last_name)" }
    self.genresBooks = dto.genres_books.map(\.name)
  }
}
