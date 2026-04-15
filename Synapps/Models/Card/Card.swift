//
//  Card.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation
import SwiftData
import SwiftUI

enum CardType: String, Codable, CaseIterable {
  case thesis
  case concept
  case idea
  case question
  case answer
  case unknown
}

@Model
final class Card {
  var id: String
  var type: CardType
  var content: String
  var references: References
  var tags: [Tag]

  init(id: String, type: CardType, content: String, references: References, tags: [Tag]) {
    self.id = id
    self.type = type
    self.content = content
    self.references = references
    self.tags = tags
  }
}

struct References: Codable {
  let pages: [Int]
  let originalTexts: [String]
}

struct Tag: Identifiable, Codable {
  let id: String
  let type: String
  let name: String
  let description: String
}

extension CardType {
  static func backgroundColors(for type: CardType?) -> [Color] {
    switch type {
    case .thesis:
      [Color(UIColor(red: 220 / 255, green: 227 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
    case .concept:
      [Color(UIColor(red: 228 / 255, green: 221 / 255, blue: 234 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1.0))]
    case .idea:
      [Color(UIColor(red: 245 / 255, green: 237 / 255, blue: 227 / 255, alpha: 1.0)), Color(UIColor(red: 243 / 255, green: 241 / 255, blue: 238 / 255, alpha: 1.0))]
    case .question:
      [Color(UIColor(red: 220 / 255, green: 225 / 255, blue: 240 / 255, alpha: 1.0)), Color(UIColor(red: 240 / 255, green: 240 / 255, blue: 243 / 255, alpha: 1.0))]
    case .answer:
      [Color(UIColor(red: 220 / 255, green: 234 / 255, blue: 221 / 255, alpha: 1.0)), Color(UIColor(red: 240 / 255, green: 243 / 255, blue: 240 / 255, alpha: 1.0))]
    case .unknown, .none:
      [Color(.systemBackground)]
    }
  }
}

extension CardType {
  var localized: String {
    switch self {
    case .thesis:
      "CardType.Thesis"
    case .concept:
      "CardType.Concept"
    case .idea:
      "CardType.Idea"
    case .question:
      "CardType.Question"
    case .answer:
      "CardType.Answer"
    case .unknown:
      "CardType.Unknown"
    }
  }

  var localizedName: LocalizedStringKey {
    LocalizedStringKey(self.localized)
  }

  static func typeColor(for type: CardType?) -> Color {
    switch type {
    case .thesis:
      Color(hex: "97ACF1")
    case .concept:
      Color(hex: "B785C6")
    case .idea:
      Color(hex: "E6A63F")
    case .question:
      Color(hex: "DCE1F0")
    case .answer:
      Color(hex: "DCEADD")
    case .unknown, .none:
      Color(.systemBackground)
    }
  }
}
