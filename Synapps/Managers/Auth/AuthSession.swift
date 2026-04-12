//
//  AuthSession.swift
//  Synapps
//

import Foundation

/// Синхронизирует login / refresh между параллельными запросами.
private actor AuthOperationCoordinator {
  private var inFlight: Task<Void, Error>?

  func run(_ work: @Sendable @escaping () async throws -> Void) async throws {
    if let existing = inFlight {
      try await existing.value
      return
    }
    let task = Task {
      try await work()
    }
    inFlight = task
    defer { inFlight = nil }
    try await task.value
  }
}

/// Автоматический login по устройству, refresh access и fallback на login при просроченном refresh.
final class AuthSession {
  private let store: AuthTokenStore
  private let rawService: Service
  private let coordinator = AuthOperationCoordinator()

  init(store: AuthTokenStore, rawService: Service) {
    self.store = store
    self.rawService = rawService
  }

  var accessToken: String? {
    store.accessToken
  }

  /// Если access token в памяти ещё нет — выполняется `POST /auth/login`.
  func loginIfNeeded() async throws {
    if store.accessToken != nil {
      return
    }
    try await coordinator.run { [weak self] in
      guard let self else { return }
      if self.store.accessToken != nil {
        return
      }
      try await self.performLogin()
    }
  }

  /// После `invalid_or_expired_token` на защищённом эндпоинте: refresh или повторный login.
  func refreshAfterExpiredAccess() async throws {
    try await coordinator.run { [weak self] in
      guard let self else { return }
      if let refresh = self.store.refreshToken {
        do {
          try await self.performRefresh(refreshToken: refresh)
        } catch let error as NetworkError {
          if case .invalidOrExpiredRefreshToken = error {
            try await self.performLogin()
          } else {
            throw error
          }
        }
      } else {
        try await self.performLogin()
      }
    }
  }

  /// Когда защищённый запрос вернул `invalid_or_expired_refresh_token` (напрямую с API).
  func recoverWithFreshLogin() async throws {
    try await coordinator.run { [weak self] in
      guard let self else { return }
      try await self.performLogin()
    }
  }

  private func performLogin() async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      guard let url = URL(string: Constants.serverURL + "/api/v1/auth/login") else {
        continuation.resume(throwing: NetworkError.invalidResponse("Некорректный URL login"))
        return
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      do {
        request.httpBody = try JSONEncoder().encode(DeviceIdentity.makeLoginRequest())
      } catch {
        continuation.resume(throwing: error)
        return
      }

      rawService.makeRequest(with: request, respModel: AuthTokenResponseDTO.self) { [weak self] response, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let response else {
          continuation.resume(throwing: NetworkError.invalidResponse())
          return
        }
        guard let self else {
          continuation.resume(throwing: NetworkError.invalidResponse())
          return
        }
        do {
          try self.store.save(tokens: response)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  private func performRefresh(refreshToken: String) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      guard let url = URL(string: Constants.serverURL + "/api/v1/auth/refresh") else {
        continuation.resume(throwing: NetworkError.invalidResponse("Некорректный URL refresh"))
        return
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      do {
        request.httpBody = try JSONEncoder().encode(RefreshRequestDTO(refreshToken: refreshToken))
      } catch {
        continuation.resume(throwing: error)
        return
      }

      rawService.makeRequest(with: request, respModel: AuthTokenResponseDTO.self) { [weak self] response, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let response else {
          continuation.resume(throwing: NetworkError.invalidResponse())
          return
        }
        guard let self else {
          continuation.resume(throwing: NetworkError.invalidResponse())
          return
        }
        do {
          try self.store.save(tokens: response)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
