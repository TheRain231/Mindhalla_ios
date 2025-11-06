//
//  NetworkError.swift
//  Synapps
//
//  Created by Andrey Stepanov on 03.11.2025.
//

import Foundation

/// Универсальная ошибка для работы с OpenAPIURLSession и URLSessionTransport
enum NetworkError: LocalizedError, Equatable {
  // MARK: - Cases

  case invalidURL
  case invalidStatus(Int)
  case decodingFailed
  case encodingFailed
  case unauthorized
  case forbidden
  case notFound
  case serverError(status: Int)
  case validationError(details: [String])
  case networkFailure(URLError)
  case unknown
  case emptyResponse

  // MARK: - Computed

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      "Некорректный адрес сервера."
    case let .invalidStatus(code):
      "Неожиданный HTTP статус: \(code)."
    case .decodingFailed:
      "Ошибка при разборе данных от сервера."
    case .encodingFailed:
      "Ошибка при подготовке тела запроса."
    case .unauthorized:
      "Необходима авторизация. Пожалуйста, войдите заново."
    case .forbidden:
      "Доступ запрещён."
    case .notFound:
      "Данные не найдены."
    case let .serverError(status):
      "Ошибка на стороне сервера (\(status)). Попробуйте позже."
    case let .validationError(details):
      "Ошибка валидации данных: \(details.joined(separator: ", "))."
    case let .networkFailure(urlError):
      "Проблема с подключением: \(urlError.localizedDescription)"
    case .unknown:
      "Неизвестная ошибка"
    case .emptyResponse:
      "Пустой ответ от сервера."
    }
  }
}
