//
//  NetworkManagerProtocol.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

import Foundation

protocol NetworkManagerProtocol {
  func getAllBooks() async throws -> [BookMetaResponse]
  func getBook(by id: String) async throws -> BookFullResponse

  func uploadBook(_ fileURL: URL) async throws -> UploadFileInfoResponse
}
