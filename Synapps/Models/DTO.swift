//
//  DTO.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import AnyCodable
import Foundation

// MARK: - Upload

struct UploadResponseDTO: Codable {
  let files: [UploadFileInfoResponseDTO]
}

struct UploadFileInfoResponseDTO: Codable {
  let id: String
  let s3Key: String
  let filename: String
  let mimetype: String
  let size: Int
  let processingStatus: String

  enum CodingKeys: String, CodingKey {
    case id
    case s3Key = "s3_key"
    case filename
    case mimetype
    case size
    case processingStatus = "processing_status"
  }
}

// MARK: - Books List

struct BooksMetaResponseDTO: Codable {
  let books: [BookMetaResponseDTO]
  let meta: PaginationMetaDTO
}

struct PaginationMetaDTO: Codable {
  let total: Int
  let limit: Int
  let offset: Int
}

struct BookMetaResponseDTO: Codable {
  let id: String?
  let title: String
  let editionNumber: Int?
  let year: Int?
  let publisher: String?
  let language: String?
  let pages: Int?
  let coverUrl: String?
  let cardsCount: Int?
  let authors: [BookAuthorResponseDTO]
  let genres: [BookGenreResponseDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case editionNumber = "edition_number"
    case year
    case publisher
    case language
    case pages
    case coverUrl = "cover_url"
    case cardsCount = "cards_count"
    case authors
    case genres
  }
}

// MARK: - Book By ID

/// Unified response for GET /books/{book_id}.
/// Returns known book info and `nil` for not-yet-available parts (e.g. cards).
struct BookByIdResponseDTO: Codable {
  let id: String
  let filename: String
  let processingStatus: String
  let totalChapters: Int?
  let processedChapters: Int?
  let title: String?
  let editionNumber: Int?
  let year: Int?
  let publisher: String?
  let language: String?
  let pages: Int?
  let coverUrl: String?
  let cards: [BookCardResponseDTO]?
  let authorsBooks: [BookAuthorResponseDTO]?
  let genresBooks: [BookGenreResponseDTO]?

  enum CodingKeys: String, CodingKey {
    case id
    case filename
    case processingStatus = "processing_status"
    case totalChapters = "total_chapters"
    case processedChapters = "processed_chapters"
    case title
    case editionNumber = "edition_number"
    case year
    case publisher
    case language
    case pages
    case coverUrl = "cover_url"
    case cards
    case authorsBooks = "authors_books"
    case genresBooks = "genres_books"
  }
}

// MARK: - Book Card

struct BookCardResponseDTO: Codable {
  let id: String
  let content: String
  let references: [String: AnyCodable]
  let tags: [BookCardTagResponseDTO]
}

struct BookCardTagResponseDTO: Codable {
  let id: String
  let type: String
  let name: String
  let description: String?
}

// MARK: - Shared

struct BookAuthorResponseDTO: Codable {
  let id: String?
  let firstName: String
  let lastName: String

  enum CodingKeys: String, CodingKey {
    case id
    case firstName = "first_name"
    case lastName = "last_name"
  }
}

struct BookGenreResponseDTO: Codable {
  let id: String?
  let name: String
  let description: String?
}

// MARK: - Validation Error

struct HTTPValidationErrorDTO: Codable {
  let detail: [ValidationErrorDTO]?
}

struct ValidationErrorDTO: Codable {
  let loc: [AnyCodable]
  let msg: String
  let type: String
}

// MARK: - Other

struct AuthTokenResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
  let tokenType: String?
  let subscriptionTier: String?

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case tokenType = "token_type"
    case subscriptionTier = "subscription_tier"
  }
}

struct Body_upload_api_v1_uploads_postDTO: Codable {
  let files: [Data]
}

struct LoginRequestDTO: Codable {
  let deviceId: String
  let brand: String?
  let model: String?
  let language: String?
  let softwareVersion: String?

  enum CodingKeys: String, CodingKey {
    case deviceId = "device_id"
    case brand
    case model
    case language
    case softwareVersion = "software_version"
  }
}

struct RefreshRequestDTO: Codable {
  let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case refreshToken = "refresh_token"
  }
}

struct SubscriptionPurchaseRequestDTO: Codable {
  let tier: String
}
