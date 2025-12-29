//
//  DTO.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import AnyCodable
import Foundation

struct BookAuthorResponseDTO: Codable {
  let id: String?
  let firstName: String
  let lastName: String

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
  }

  init(id: String? = nil, firstName: String = "", lastName: String = "") {
    self.id = id
    self.firstName = firstName
    self.lastName = lastName
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id)
    self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
    self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
  }
}

struct BookCardTagResponseDTO: Codable {
  let id: String
  let type: String
  let name: String
  let description: String?

  enum CodingKeys: String, CodingKey {
    case id
    case type
    case name
    case description
  }

  init(id: String = "", type: String = "", name: String = "", description: String? = nil) {
    self.id = id
    self.type = type
    self.name = name
    self.description = description
  }
}

struct BookCardResponseDTO: Decodable {
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
    case content
  }

  init(id: String = "", type: String = "", context: String = "", references: [String: AnyCodable] = [:], tags: [BookCardTagResponseDTO] = []) {
    self.id = id
    self.type = type
    self.context = context
    self.references = references
    self.tags = tags
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""

    // support both `content` and `context` field names
    if let content = try? container.decodeIfPresent(String.self, forKey: .content) {
      self.context = content
    } else {
      self.context = try container.decodeIfPresent(String.self, forKey: .context) ?? ""
    }

    self.references = try container.decodeIfPresent([String: AnyCodable].self, forKey: .references) ?? [:]
    self.tags = try container.decodeIfPresent([BookCardTagResponseDTO].self, forKey: .tags) ?? []
  }
}

struct BookGenreResponseDTO: Codable {
  let id: String?
  let name: String
  let description: String?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
  }

  init(id: String? = nil, name: String = "", description: String? = nil) {
    self.id = id
    self.name = name
    self.description = description
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id)
    self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    self.description = try container.decodeIfPresent(String.self, forKey: .description)
  }
}

struct BookFullResponseDTO: Decodable {
  let id: String
  let title: String
  let editionNumber: Int?
  let year: Int?
  let publisher: String
  let language: String?
  let pages: Int?
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

  init(id: String = "", title: String = "", editionNumber: Int? = nil, year: Int? = nil, publisher: String = "", language: String? = nil, pages: Int? = nil, cards: [BookCardResponseDTO] = [], authorsBooks: [BookAuthorResponseDTO] = [], genresBooks: [BookGenreResponseDTO] = []) {
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
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    self.editionNumber = try container.decodeIfPresent(Int.self, forKey: .editionNumber)
    self.year = try container.decodeIfPresent(Int.self, forKey: .year)
    self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher) ?? ""
    self.language = try container.decodeIfPresent(String.self, forKey: .language)
    self.pages = try container.decodeIfPresent(Int.self, forKey: .pages)
    self.cards = try container.decodeIfPresent([BookCardResponseDTO].self, forKey: .cards) ?? []
    self.authorsBooks = try container.decodeIfPresent([BookAuthorResponseDTO].self, forKey: .authorsBooks) ?? []
    self.genresBooks = try container.decodeIfPresent([BookGenreResponseDTO].self, forKey: .genresBooks) ?? []
  }
}

struct BookMetaResponseDTO: Codable {
  let id: String
  let title: String
  let editionNumber: Int
  let year: Int
  let publisher: String
  let authors: String
  let genres: String

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case editionNumber = "edition_number"
    case year
    case publisher
    case authors
    case genres
  }

  init(
    id: String = UUID().uuidString,
    title: String,
    editionNumber: Int = 0,
    year: Int = 0,
    publisher: String,
    authors: String = "",
    genres: String = ""
  ) {
    self.id = id
    self.title = title
    self.editionNumber = editionNumber
    self.year = year
    self.publisher = publisher
    self.authors = authors
    self.genres = genres
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.title = try container.decode(String.self, forKey: .title)
    self.editionNumber = try container.decodeIfPresent(Int.self, forKey: .editionNumber) ?? 0
    self.year = try container.decodeIfPresent(Int.self, forKey: .year) ?? 0
    self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher) ?? ""

    if let authorsArray = try? container.decode([String].self, forKey: .authors) {
      self.authors = authorsArray.joined(separator: ", ")
    } else if let authorsString = try? container.decode(String.self, forKey: .authors) {
      self.authors = authorsString
    } else {
      self.authors = ""
    }

    if let genresString = try? container.decode(String.self, forKey: .genres) {
      self.genres = genresString
    } else if let genresArray = try? container.decode([BookGenreResponseDTO].self, forKey: .genres) {
      self.genres = genresArray.map(\.name).joined(separator: ", ")
    } else {
      self.genres = ""
    }
  }
}

struct BooksMetaResponseDTO: Codable {
  let books: [BookMetaResponseDTO]
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
