import Foundation
import SwiftUI

extension Color {
  init(hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: alpha
    )
  }

  /// RGB (`"9B60E9"`, `"#9B60E9"`) или RGBA (`"9B60E9FF"`).
  init(hex: String, alpha: Double = 1) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") {
      s.removeFirst()
    }

    var value: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&value) else {
      self = .clear
      return
    }

    switch s.count {
    case 6:
      self.init(hex: UInt(value), alpha: alpha)
    case 8:
      let rgb = UInt((value >> 8) & 0xffffff)
      let embeddedAlpha = Double(value & 0xff) / 255
      self.init(hex: rgb, alpha: embeddedAlpha * alpha)
    default:
      self = .clear
    }
  }
}

