//
//  NetworkError.swift
//  Synapps
//
//  Created by Andrey Stepanov on 03.11.2025.
//

import Foundation

enum NetworkError: Error, LocalizedError {
  case urlSessionError(String)
  case serverError(String = "Server error")
  case invalidResponse(String = "Invalid response from server.")
  case decodingError(String = "Error parsing server response.")

  var errorDescription: String? {
    switch self {
    case let .urlSessionError(message),
         let .serverError(message),
         let .invalidResponse(message),
         let .decodingError(message):
      message
    }
  }
}
