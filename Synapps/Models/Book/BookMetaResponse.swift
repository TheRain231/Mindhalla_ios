//
//  BookMetaResponse.swift
//  Synapps
//
//  Created by Andrey Stepanov on 11.11.2025.
//

import Foundation

struct BookMetaResponse: Identifiable, Hashable, Codable {
  let id: String
  let title: String
  let editionNumber: Int
  let year: Int
  let publisher: String
  let authors: String
  let genres: String

  let coverImageUrl: URL?
}
