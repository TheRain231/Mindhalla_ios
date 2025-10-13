//
//  Card.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

enum CardType: Codable {
  case thesis
  case concept
  case idea
}

struct Card: Identifiable, Codable {
  let id: String
  let type: CardType
  let context: String
  let references: References
  let tags: [Tag]
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
