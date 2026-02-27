//
//  DTO.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import AnyCodable
import Foundation

struct BookAuthorResponseDTO: Codable {
  let id: String
  let firstName: String
  let lastName: String

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
  }
}

struct BookCardTagResponseDTO: Codable {
  let id: String
  let type: String
  let name: String
  let description: String
}

struct BookCardResponseDTO: Codable {
  let id: String
  let type: String
  let context: String
  let references: [String: AnyCodable]
  let tags: [BookCardTagResponseDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case context
    case references
    case tags
  }
}

struct BookGenreResponseDTO: Codable {
  let id: String
  let name: String
  let description: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
  }
}

struct BookFullResponseDTO: Codable {
  let id: String
  let title: String
  let editionNumber: Int
  let year: Int
  let publisher: String
  let language: String
  let pages: Int
  let cards: [BookCardResponseDTO]
  let authorsBooks: [BookAuthorResponseDTO]
  let genresBooks: [BookGenreResponseDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case editionNumber = "edition_number"
    case year
    case publisher
    case language
    case pages
    case cards
    case authorsBooks = "authors_books"
    case genresBooks = "genres_books"
  }
}

struct BookMetaResponseDTO: Codable {
  let id: String?
  let title: String
  let editionNumber: Int?
  let year: Int?
  let publisher: String
  let language: String?
  let authors: [BooksAuthor]
  let genres: [BooksGenre]

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case editionNumber = "edition_number"
    case year
    case publisher
    case language
    case authors
    case genres
  }
}

struct BooksAuthor: Codable {
  let id: String?
  let firstName: String
  let lastName: String
}

struct BooksGenre: Codable {
  let id: String?
  let name: String
  let desciption: String?
}

struct BooksMetaResponseDTO: Codable {
  let books: [BookMetaResponseDTO]
  let meta: [BooksMeta]
}

struct BooksMeta: Codable {
  let total: Int
  let limit: Int
  let offset: Int
}

struct HTTPValidationErrorDTO: Codable {
  let detail: [ValidationErrorDTO]?
}

struct S3PayloadDTO: Codable {
  let key: String
}

struct UploadFileInfoResponseDTO: Codable {
  let id: String
  let s3Key: String
  let filename: String
  let mimetype: String
  let size: Int

  enum CodingKeys: String, CodingKey {
    case id
    case s3Key = "s3_key"
    case filename
    case mimetype
    case size
  }
}

struct UploadRequestDTO: Codable {
  let files: [String]
}

struct UploadResponseDTO: Codable {
  let files: [UploadFileInfoResponseDTO]
}

struct ValidationErrorDTO: Codable {
  let loc: [AnyCodable]
  let msg: String
  let type: String
}
