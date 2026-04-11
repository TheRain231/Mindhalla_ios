//
//  AuthTokenStore.swift
//  Synapps
//

import Foundation

/// Хранение access JWT в памяти и refresh JWT в Keychain.
final class AuthTokenStore {
  private let service = "com.mindhalla.Synapps.auth.tokens"
  private var cachedAccessToken: String?

  private enum Account {
    static let refresh = "refresh_token"
  }

  var accessToken: String? {
    cachedAccessToken
  }

  var refreshToken: String? {
    KeychainHelper.get(service: service, account: Account.refresh)
  }

  func save(tokens: AuthTokenResponseDTO) throws {
    cachedAccessToken = tokens.accessToken
    try KeychainHelper.set(tokens.refreshToken, service: service, account: Account.refresh)
  }

  func clear() {
    cachedAccessToken = nil
    KeychainHelper.delete(service: service, account: Account.refresh)
  }
}
