//
//  DeviceIdentity.swift
//  Synapps
//

import Foundation
import UIKit

enum DeviceIdentity {
  /// Тело для `POST /api/v1/auth/login` без участия пользователя.
  static func makeLoginRequest() -> LoginRequestDTO {
    LoginRequestDTO(
      deviceId: persistentDeviceId,
      brand: "Apple",
      model: machineModelIdentifier,
      language: preferredLanguageCode,
      softwareVersion: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    )
  }

  private static var persistentDeviceId: String {
    if let id = UIDevice.current.identifierForVendor?.uuidString {
      return id
    }
    let key = "synapps.fallback.device_id"
    if let existing = UserDefaults.standard.string(forKey: key) {
      return existing
    }
    let uuid = UUID().uuidString
    UserDefaults.standard.set(uuid, forKey: key)
    return uuid
  }

  private static var preferredLanguageCode: String {
    Locale.current.language.languageCode?.identifier
      ?? Locale.preferredLanguages.first.map { String($0.prefix(while: { $0 != "-" })) }
      ?? "en"
  }

  /// Hardware model, e.g. `iPhone15,2`; fallback — `UIDevice.current.model`.
  private static var machineModelIdentifier: String {
    var uts = utsname()
    guard uname(&uts) == 0 else {
      return UIDevice.current.model
    }
    let machine = uts.machine // Copy the tuple to a local variable, type [Int8]
    let name = withUnsafePointer(to: machine) { ptr in
      ptr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: machine)) {
        String(cString: $0)
      }
    }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? UIDevice.current.model : trimmed
  }
}
