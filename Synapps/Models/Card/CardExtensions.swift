//
//  CardExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

extension Card: Equatable {
  static func ==(lhs: Card, rhs: Card) -> Bool {
    lhs.id == rhs.id
  }
}

extension Card {
  static func color(for type: CardType) -> Color {
    switch type {
    case .thesis:
      .blue
    case .concept:
      .purple
    case .idea:
      .orange
    }
  }
}

extension Card {
  func sourceDescription() -> String {
    "Тут было описание главы до смены модели карточки"
//    "Глава \(source.chapterNumber) • \(source.chapterName) • с \(source.pageNumber)"
  }
}

#if DEBUG
extension Card {
  static func mock(type: CardType = .thesis) -> Card {
    switch type {
    case .thesis:
      Card(
        id: "c26b27dc-ef2e-46f9-823f-77afa820c202",
        type: .thesis,
        context: "The Sorting Hat scene and its moral about choice and courage.",
        references: .init(
          pages: [
            88,
            90,
          ],
          originalTexts: ["It is our choices, Harry, that show what we truly are..."]
        ),
        tags: [
          .init(id: "c26b27dc-ef2e-46f9-823f-77afa820c203", type: "system", name: "moral", description: "Central moral lesson of the book."),
          .init(id: "c26b27dc-ef2e-46f9-823f-77afa820c204", type: "custom", name: "hogwarts", description: "Key scene set in the Great Hall."),
        ]
      )
    case .concept:
      Card(
        id: "b17b18cc-ef3d-46f9-823f-99afa830c101",
        type: .concept,
        context: "Harry receives his first letter from Hogwarts.",
        references: .init(
          pages: [
            45,
            46,
          ],
          originalTexts: ["No post on Sundays... except for one peculiar letter."]
        ),
        tags: [
          .init(id: "b17b18cc-ef3d-46f9-823f-99afa830c102", type: "custom", name: "letter", description: "First sign of magic entering his life."),
          .init(id: "b17b18cc-ef3d-46f9-823f-99afa830c103", type: "system", name: "plot-start", description: "Beginning of the story's main conflict."),
        ]
      )
    case .idea:
      Card(
        id: "f8f4b3cc-ef8d-46f9-823f-89afae30c91a",
        type: .idea,
        context: "Introduction to the Dursleys...",
        references: .init(
          pages: [
            1,
            2,
          ],
          originalTexts: ["Mr. and Mrs. Dursley of number four..."]
        ),
        tags: [
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c91a", type: "system", name: "some-tag-1", description: "some description 1"),
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c912", type: "system", name: "some-tag-2", description: "some description 2"),
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c913", type: "system", name: "some-tag-3", description: "some description 3"),
        ]
      )
    }
  }

  static func mockThesis() -> Card { mock(type: .thesis) }
  static func mockConcept() -> Card { mock(type: .concept) }
  static func mockQuote() -> Card { mock(type: .idea) }

  static func mocks() -> [Card] {
    [mockThesis(), mockConcept(), mockQuote()]
  }
}
#endif
