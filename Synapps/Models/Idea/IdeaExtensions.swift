//
//  IdeaExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

extension Idea {
  static func color(for type: IdeaType) -> Color {
    switch type {
    case .Thesis:
      .blue
    case .Concept:
      .purple
    case .Quote:
      .orange
    }
  }
}

extension Idea {
  func sourceDescription() -> String {
    "Глава \(source.chapterNumber) • \(source.chapterName) • с \(source.pageNumber)"
  }
}

#if DEBUG
extension Idea {
  static func mock(type: IdeaType = .Thesis) -> Idea {
    let source = IdeaSource(
      book: Book.mock(),
      chapterNumber: 1,
      chapterName: "Введение",
      pageNumber: 10
    )

    switch type {
    case .Thesis:
      return Idea(
        text: "Краткая тезисная мысль о ключевой идее книги.",
        author: nil,
        source: source,
        type: .Thesis
      )
    case .Concept:
      return Idea(
        text: "Описание концепции: как работает подход XYZ и почему это важно.",
        author: nil,
        source: source,
        type: .Concept
      )
    case .Quote:
      return Idea(
        text: "«Это пример цитаты, которая достойна сохранения.»",
        author: "Mock Quote Author",
        source: source,
        type: .Quote
      )
    }
  }

  static func mockThesis() -> Idea { mock(type: .Thesis) }
  static func mockConcept() -> Idea { mock(type: .Concept) }
  static func mockQuote() -> Idea { mock(type: .Quote) }

  static func mocks() -> [Idea] {
    [mockThesis(), mockConcept(), mockQuote()]
  }
}
#endif
