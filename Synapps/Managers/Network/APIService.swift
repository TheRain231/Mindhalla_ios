//
//  APIService.swift
//  Synapps
//
//  Created by Андрей Степанов on 29.03.2025.
//

import Foundation

protocol Service {
  func makeRequest<T: Codable>(with request: URLRequest, respModel: T.Type, completion: @escaping (T?, NetworkError?) -> Void)
}

class APIService: Service {
  let urlSession: URLSession

  init(urlSession: URLSession) {
    self.urlSession = urlSession
  }

  func makeRequest<T: Codable>(
    with request: URLRequest,
    respModel _: T.Type,
    completion: @escaping (T?, NetworkError?) -> Void
  ) {
    urlSession.dataTask(with: request) { data, resp, error in
      if let error {
        completion(nil, .urlSessionError(error.localizedDescription))
        return
      }

      guard let httpResponse = resp as? HTTPURLResponse else {
        completion(nil, .invalidResponse())
        return
      }

      guard let data else {
        completion(nil, .invalidResponse())
        return
      }

      do {
        switch httpResponse.statusCode {
        case 200..<300:
          if T.self == Data.self {
            completion(data as? T, nil)
            return
          }

          let result = try JSONDecoder.iso8601withTimeZone.decode(T.self, from: data)
          completion(result, nil)
          return

        case 401:
          if let dto = try? JSONDecoder().decode(ErrorDetailDTO.self, from: data),
             let detail = dto.detail {
            switch detail {
            case "invalid_or_expired_token":
              completion(nil, .invalidOrExpiredAccessToken)
            case "invalid_or_expired_refresh_token":
              completion(nil, .invalidOrExpiredRefreshToken)
            default:
              completion(nil, .serverError(detail))
            }
          } else {
            completion(nil, .serverError())
          }
          return

        case 422:
          if let errorResponse = try? JSONDecoder().decode(HTTPValidationErrorDTO.self, from: data) {
            let message = errorResponse.detail?.map(\.msg).joined(separator: "\n") ?? ""
            completion(nil, .serverError(message))
            return
          }

          if let errorResponse = try? JSONDecoder().decode(ValidationErrorDTO.self, from: data) {
            completion(nil, .serverError(errorResponse.msg))
            return
          }

          completion(nil, .serverError())
          return

        case 400..<500:
          if let errorResponse = try? JSONDecoder().decode(ValidationErrorDTO.self, from: data) {
            completion(nil, .serverError(errorResponse.msg))
            return
          }
          if let errorResponse = try? JSONDecoder().decode(HTTPValidationErrorDTO.self, from: data) {
            let message = errorResponse.detail?.map(\.msg).joined(separator: "\n") ?? ""
            completion(nil, .serverError(message))
            return
          }

          completion(nil, .serverError())
          return

        case 500..<600:
          completion(nil, .serverError())
          return

        default:
          completion(nil, .invalidResponse())
          return
        }
      } catch {
        print(error)
        completion(nil, .decodingError())
      }
    }.resume()
  }
}

extension JSONDecoder {
  static let iso8601withTimeZone: JSONDecoder = {
    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Или .XXX для +00:00
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
  }()
}
