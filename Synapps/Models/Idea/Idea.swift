//
//  Idea.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

enum IdeaType {
  case Thesis
  case Concept
  case Quote
}

struct IdeaSource {
  let book: Book
  let chapterNumber: Int
  let chapterName: String
  let pageNumber: Int
}

struct Idea: Identifiable {
  let id = UUID()
  let text: String
  let author: String?
  let source: IdeaSource
  let type: IdeaType
}
