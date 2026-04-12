//
//  AuthenticatedAPIService.swift
//  Synapps
//

import Foundation

/// Подставляет Bearer access token и обрабатывает просроченные JWT согласно ответам API.
final class AuthenticatedAPIService: Service {
  private let inner: Service
  private let authSession: AuthSession

  init(inner: Service, authSession: AuthSession) {
    self.inner = inner
    self.authSession = authSession
  }

  func makeRequest<T: Codable>(
    with request: URLRequest,
    respModel: T.Type,
    completion: @escaping (T?, NetworkError?) -> Void
  ) {
    Task { [weak self] in
      guard let self else {
        completion(nil, .invalidResponse())
        return
      }
      do {
        var authorized = request
        if Self.requestsAuthorization(request) {
          try await authSession.loginIfNeeded()
          if let token = authSession.accessToken {
            authorized.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
          }
        }

        self.performOnce(
          request: authorized,
          originalRequest: request,
          respModel: respModel,
          attempt: 0,
          completion: completion
        )
      } catch let error as NetworkError {
        completion(nil, error)
      } catch {
        completion(nil, .urlSessionError(error.localizedDescription))
      }
    }
  }

  private func performOnce<T: Codable>(
    request: URLRequest,
    originalRequest: URLRequest,
    respModel: T.Type,
    attempt: Int,
    completion: @escaping (T?, NetworkError?) -> Void
  ) {
    inner.makeRequest(with: request, respModel: respModel) { [weak self] response, error in
      guard let self else {
        completion(nil, .invalidResponse())
        return
      }

      guard let error else {
        completion(response, nil)
        return
      }

      guard attempt == 0, Self.requestsAuthorization(originalRequest) else {
        completion(nil, error)
        return
      }

      if case .invalidOrExpiredAccessToken = error {
        Task {
          do {
            try await self.authSession.refreshAfterExpiredAccess()
            var retry = originalRequest
            if let token = self.authSession.accessToken {
              retry.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            self.performOnce(
              request: retry,
              originalRequest: originalRequest,
              respModel: respModel,
              attempt: attempt + 1,
              completion: completion
            )
          } catch let netError as NetworkError {
            completion(nil, netError)
          } catch {
            completion(nil, .urlSessionError(error.localizedDescription))
          }
        }
        return
      }

      if case .invalidOrExpiredRefreshToken = error {
        Task {
          do {
            try await self.authSession.recoverWithFreshLogin()
            var retry = originalRequest
            if let token = self.authSession.accessToken {
              retry.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            self.performOnce(
              request: retry,
              originalRequest: originalRequest,
              respModel: respModel,
              attempt: attempt + 1,
              completion: completion
            )
          } catch let netError as NetworkError {
            completion(nil, netError)
          } catch {
            completion(nil, .urlSessionError(error.localizedDescription))
          }
        }
        return
      }

      completion(nil, error)
    }
  }

  private static func requestsAuthorization(_ request: URLRequest) -> Bool {
    guard let path = request.url?.path else { return true }
    return path != "/api/v1/auth/login" && path != "/api/v1/auth/refresh"
  }
}
