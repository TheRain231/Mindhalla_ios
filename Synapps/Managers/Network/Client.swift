//
//  Client.swift
//  Synapps
//
//  Created by Andrey Stepanov on 17.11.2025.
//

import Foundation

protocol ClientProtocol {
  func getAllBooks(completion: @escaping (BooksMetaResponseDTO?, NetworkError?) -> Void)
  func getBookById(id: String, completion: @escaping (BookFullResponseDTO?, NetworkError?) -> Void)
  func uploadBook(_ fileURL: URL, completion: @escaping (UploadResponseDTO?, NetworkError?) -> Void)
}

final class Client: ClientProtocol {
  private let service: Service

  init(service: Service) {
    self.service = service
  }

  func getAllBooks(completion: @escaping (BooksMetaResponseDTO?, NetworkError?) -> Void) {
    guard let urlRequest = Endpoint.getAllBooks.request else {
      completion(nil, .invalidResponse("Invalid URLRequest for getAllBooks"))
      return
    }

    service.makeRequest(with: urlRequest, respModel: BooksMetaResponseDTO.self) { response, error in
      completion(response, error)
    }
  }

  func getBookById(id: String, completion: @escaping (BookFullResponseDTO?, NetworkError?) -> Void) {
    guard let urlRequest = Endpoint.getBookById(id: id).request else {
      completion(nil, .invalidResponse("Invalid URLRequest for getBookById"))
      return
    }

    service.makeRequest(with: urlRequest, respModel: BookFullResponseDTO.self) { response, error in
      completion(response, error)
    }
  }

  func uploadBook(_ fileURL: URL, completion: @escaping (UploadResponseDTO?, NetworkError?) -> Void) {
    guard let urlRequest = Endpoint.uploadBook(fileURL: fileURL).request else {
      completion(nil, .invalidResponse("Invalid URLRequest for uploadBook"))
      return
    }

    service.makeRequest(with: urlRequest, respModel: UploadResponseDTO.self) { response, error in
      completion(response, error)
    }
  }
}
