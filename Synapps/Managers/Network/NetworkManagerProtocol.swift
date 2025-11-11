//
//  NetworkManagerProtocol.swift
//  Synapps
//
//  Created by Andrey Stepanov on 18.10.2025.
//

protocol NetworkManagerProtocol {
  func getAllBooks() async throws -> [BookMetaResponse]
  func getBook(by id: String) async throws -> BookFullResponse
}
