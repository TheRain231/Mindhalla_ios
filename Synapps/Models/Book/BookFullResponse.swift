//
//  BookFullResponse.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation
import SwiftData

@Model
final class BookByIdResponse {
  var id: String
  var title: String
  var editionNumber: Int
  var year: Int
  var publisher: String
  var language: String
  var pages: Int
  var cards: [Card]
  var authorsBooks: [String]
  var genresBooks: [String]
  var processingStatus: String
  var coverImageUrl: URL?
  var filename: String
  var totalChapters: Int?
  var processedChapters: Int?

  init(id: String, title: String, editionNumber: Int, year: Int, publisher: String, language: String, pages: Int, cards: [Card], authorsBooks: [String], genresBooks: [String], processingStatus: String = "done", coverImageUrl: URL? = nil, filename: String = "", totalChapters: Int? = nil, processedChapters: Int? = nil) {
    self.id = id
    self.title = title
    self.editionNumber = editionNumber
    self.year = year
    self.publisher = publisher
    self.language = language
    self.pages = pages
    self.cards = cards
    self.authorsBooks = authorsBooks
    self.genresBooks = genresBooks
    self.processingStatus = processingStatus
    self.coverImageUrl = coverImageUrl
    self.filename = filename
    self.totalChapters = totalChapters
    self.processedChapters = processedChapters
  }

  enum CodingKeys: String, CodingKey {
    case id, title, editionNumber = "edition_number", year, publisher, language, pages
    case cards
    case authorsBooks = "authors_books"
    case genresBooks = "genres_books"
  }
}
