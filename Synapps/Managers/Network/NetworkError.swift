//
//  NetworkError.swift
//  Synapps
//
//  Created by Andrey Stepanov on 03.11.2025.
//

import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
  case urlSessionError(String)
  case serverError(String = "Server error")
  case invalidResponse(String = "Invalid response from server.")
  case decodingError(String = "Error parsing server response.")
  /// Access JWT недействителен или истёк (ответ API: `detail` = `invalid_or_expired_token`).
  case invalidOrExpiredAccessToken
  /// Refresh JWT недействителен или истёк (ответ API: `detail` = `invalid_or_expired_refresh_token`).
  case invalidOrExpiredRefreshToken

  var errorDescription: String? {
    switch self {
    case let .urlSessionError(message),
         let .serverError(message),
         let .invalidResponse(message),
         let .decodingError(message):
      message
    case .invalidOrExpiredAccessToken:
      "Сессия истекла."
    case .invalidOrExpiredRefreshToken:
      "Требуется повторный вход."
    }
  }
}
