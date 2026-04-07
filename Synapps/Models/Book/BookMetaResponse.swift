//
//  BookMetaResponse.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation
import SwiftData

@Model
final class BookMetaResponse {
  var id: String
  var title: String
  var editionNumber: Int
  var year: Int
  var publisher: String?
  var authors: [String]
  var genres: [String]

  var coverImageUrl: URL?

  init(id: String, title: String, editionNumber: Int, year: Int, publisher: String?, authors: [String], genres: [String], coverImageUrl: URL? = nil) {
    self.id = id
    self.title = title
    self.editionNumber = editionNumber
    self.year = year
    self.publisher = publisher
    self.authors = authors
    self.genres = genres
    self.coverImageUrl = coverImageUrl
  }
}
