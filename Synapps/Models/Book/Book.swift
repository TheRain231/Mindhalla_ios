//
//  Book.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

struct BookSummary: Identifiable, Codable {
  let id: String
  let title: String
  let editionNumber: Int
  let year: Int
  let publisher: String
  let authors: String
  let genres: String

  // опционально — можно позже добавить image
  let coverImageUrl: URL?
}

struct BookDetail: Identifiable, Codable {
  let id: String
  let title: String
  let editionNumber: Int
  let year: Int
  let publisher: String
  let language: String
  let pages: Int
  let cards: [Card]
  let authorsBooks: [String]
  let genresBooks: [String]

  enum CodingKeys: String, CodingKey {
    case id, title, editionNumber = "edition_number", year, publisher, language, pages
    case cards
    case authorsBooks = "authors_books"
    case genresBooks = "genres_books"
  }
}
