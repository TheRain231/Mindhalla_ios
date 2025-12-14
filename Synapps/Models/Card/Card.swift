//
//  Card.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation
import SwiftData

enum CardType: String, Codable {
  case thesis
  case concept
  case idea
  case unknown
}

@Model
final class Card {
  var id: String
  var type: CardType
  var context: String
  var references: References
  var tags: [Tag]

  init(id: String, type: CardType, context: String, references: References, tags: [Tag]) {
    self.id = id
    self.type = type
    self.context = context
    self.references = references
    self.tags = tags
  }
}

struct References: Codable {
  let pages: [Int]
  let originalTexts: [String]

  enum CodingKeys: String, CodingKey {
    case pages
    case originalTexts = "original_texts"
  }
}

struct Tag: Identifiable, Codable {
  let id: String
  let type: String
  let name: String
  let description: String
}
