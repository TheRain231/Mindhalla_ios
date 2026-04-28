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
  var processingStatus: String?
  var filename: String?
  var totalChapters: Int?
  var processedChapters: Int?

  init(id: String, title: String, editionNumber: Int, year: Int, publisher: String?, authors: [String], genres: [String], coverImageUrl: URL? = nil, processingStatus: String? = nil, filename: String? = nil, totalChapters: Int? = nil, processedChapters: Int? = nil) {
    self.id = id
    self.title = title
    self.editionNumber = editionNumber
    self.year = year
    self.publisher = publisher
    self.authors = authors
    self.genres = genres
    self.coverImageUrl = coverImageUrl
    self.processingStatus = processingStatus
    self.filename = filename
    self.totalChapters = totalChapters
    self.processedChapters = processedChapters
  }

  var isProcessing: Bool { processingStatus == "in_progress" || processingStatus == "pending" }
  var hasFailed: Bool { processingStatus == "failed" }

  var processingPercentage: Int {
    guard let total = totalChapters, total > 0,
          let processed = processedChapters else { return 0 }
    return min(100, Int(Double(processed) / Double(total) * 100))
  }

  // Stubs — populated in future reading progress implementation
  var savedIdeasCount: Int { 0 }
  var percentageRead: Double { 0 }
  var timeToRead: Double { 0 }
}
