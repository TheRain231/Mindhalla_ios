//
//  BookFullResponseExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation

extension BookByIdResponse {
  convenience init(dto: BookByIdResponseDTO) {
    self.init(
      id: dto.id,
      title: dto.title ?? "",
      editionNumber: dto.editionNumber ?? 0,
      year: dto.year ?? 0,
      publisher: dto.publisher ?? "",
      language: dto.language ?? "",
      pages: dto.pages ?? 0,
      cards: dto.cards?.map {
        Card(
          dto: $0
        )
      } ?? [],
      authorsBooks: dto.authorsBooks?.map {
        "\($0.firstName) \($0.lastName)"
      } ?? [],
      genresBooks: dto.genresBooks?.map(\.name) ?? []
    )
  }
}
