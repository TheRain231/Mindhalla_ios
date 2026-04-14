//
//  CardExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation
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
    case .question:
      .indigo
    case .answer:
      .green
    case .unknown:
      .gray
    }
  }
}

extension Card {
  func sourceDescription() -> String {
    "Тут было описание главы до смены модели карточки"
//    "Глава \(source.chapterNumber) • \(source.chapterName) • с \(source.pageNumber)"
  }
}

extension Card {
  convenience init(dto: BookCardResponseDTO) {
    let type: CardType = .idea
//    if let parsedType = CardType(rawValue: dto.type) {
//      parsedType
//    } else {
//      .idea
//    }

    let dict = dto.references as [String: Any]
    let references = if let pages = dict["pages"] as? [Int],
                        let originalTexts = dict["original_texts"] as? [String] {
      References(pages: pages, originalTexts: originalTexts)
    } else {
      References(pages: [], originalTexts: [])
    }

    self.init(
      id: dto.id,
      type: type,
      content: dto.content,
      references: references,
      tags: dto.tags.map { Tag(dto: $0) }
    )
  }
}

extension References {
  init(dto: [String: Codable]) {
    let pages = dto["pages"] as? [Int] ?? []
    let texts = dto["original_texts"] as? [String] ?? []
    self.init(pages: pages, originalTexts: texts)
  }
}

extension Tag {
  init(dto: BookCardTagResponseDTO) {
    self.id = dto.id
    self.type = dto.type
    self.name = dto.name
    self.description = dto.description ?? ""
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
        content: "The Sorting Hat scene and its moral about choice and courage.",
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
        content: "Harry receives his first letter from Hogwarts.",
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
        content: "Introduction to the Dursleys...",
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
    case .question:
      Card(
        id: "q-mock-1",
        type: .question,
        content: "Что показывает наш истинный характер?",
        references: .init(pages: [], originalTexts: []),
        tags: []
      )
    case .answer:
      Card(
        id: "a-mock-1",
        type: .answer,
        content: "Не наши способности определяют, кто мы, а наш выбор.",
        references: .init(pages: [], originalTexts: []),
        tags: []
      )
    case .unknown:
      Card(
        id: "0",
        type: .unknown,
        content: "...",
        references: .init(
          pages: [],
          originalTexts: []
        ),
        tags: [
          .init(id: "0", type: "system", name: "some-tag-1", description: "some description 1"),
          .init(id: "0", type: "system", name: "some-tag-2", description: "some description 2"),
          .init(id: "0", type: "system", name: "some-tag-3", description: "some description 3"),
        ]
      )
    }
  }

  static func mockThesis() -> Card { mock(type: .thesis) }
  static func mockConcept() -> Card { mock(type: .concept) }
  static func mockQuote() -> Card { mock(type: .idea) }

  /// Карточки для подборки «Утреннее чтение» (`c-1` … `c-10`).
  static func mockMorningCards() -> [Card] {
    [
      Card(
        id: "c-1",
        type: .thesis,
        content: "День.",
        references: .init(pages: [1], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-2",
        type: .idea,
        content: "Первые минуты после пробуждения задают настрой: не телефон, а одна строка в дневнике.",
        references: .init(pages: [2], originalTexts: []),
        tags: [.init(id: "tag-c-2", type: "custom", name: "утро", description: "")]
      ),
      Card(
        id: "c-3",
        type: .concept,
        content: "Свет, вода, тишина — три опоры утреннего внимания без лишних стимулов.",
        references: .init(pages: [3], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-4",
        type: .idea,
        content: "Что сегодня действительно важно — не срочное, а значимое?",
        references: .init(pages: [4], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-5",
        type: .idea,
        content: "Короткая прогулка или растяжка перед чтением снижают «шум» в голове и помогают лучше запоминать смысл, а не отдельные фразы.",
        references: .init(pages: [5], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-6",
        type: .thesis,
        content: "Чтение утром — это не про количество страниц, а про ясность: одна идея, которую можно применить до обеда, ценнее десяти забытых абзацев.",
        references: .init(pages: [6, 7], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-7",
        type: .idea,
        content: "Заметка.",
        references: .init(pages: [8], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-8",
        type: .concept,
        content: "Если вчерашний день закончился на раздражении, утреннее чтение можно начать с короткого списка благодарностей — не как ритуал «для галочки», а как способ сместить фокус с оценки себя на наблюдение за тем, что уже есть и что можно бережно развить.",
        references: .init(pages: [9, 10], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-9",
        type: .concept,
        content: "Какую одну мысль из прочитанного я хочу проверить в действии сегодня — и как пойму, что эксперимент удался?",
        references: .init(pages: [11], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-10",
        type: .thesis,
        content: "Утреннее чтение связывает «кто я хочу быть» с «что я делаю в первый час»: не геройством, а маленькой последовательностью — открыть книгу, прочитать абзац, записать вывод. Так день начинается не из тревоги списка дел, а из выбранного смысла, который потом проще переносить в работу, отношения и отдых без чувства, что жизнь распалась на несовместимые куски.",
        references: .init(pages: [12, 13, 14], originalTexts: []),
        tags: [.init(id: "tag-c-10", type: "system", name: "ритуал", description: "")]
      ),
    ]
  }

  /// Пять разных карточек для подборки «Идеи для работы» (`c-11` … `c-15`).
  static func mockWorkCards() -> [Card] {
    [
      Card(
        id: "c-11",
        type: .thesis,
        content: "Сначала результат, потом процесс: формулируй исход, который можно проверить к пятнице.",
        references: .init(pages: [20], originalTexts: []),
        tags: [.init(id: "tag-w-11", type: "custom", name: "фокус", description: "")]
      ),
      Card(
        id: "c-12",
        type: .idea,
        content: "Нет.",
        references: .init(pages: [21], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-13",
        type: .concept,
        content: "Разбей большую задачу на шаги по 25 минут: после каждого блока — одна строка в логе, что изменилось в понимании проблемы, а не только в объёме сделанного.",
        references: .init(pages: [22, 23], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-14",
        type: .thesis,
        content: "Кому нужен этот отчёт через месяц — тебе, команде или формальности? От ответа зависит глубина анализа и границы «достаточно хорошо».",
        references: .init(pages: [24], originalTexts: []),
        tags: []
      ),
      Card(
        id: "c-15",
        type: .idea,
        content: "Когда встречи съедают день, оставь два окна без календаря: одно — для глубокой работы с одним документом, другое — для разбора входящих без немедленных ответов. Так ты возвращаешь инициативу: не поток уведомлений решает, что важно, а заранее выбранный приоритет, к которому можно вернуться после шума, не теряя нить рассуждений и не превращая вечер в догоняние задач, которые утром казались мелочами.",
        references: .init(pages: [25, 26, 27], originalTexts: []),
        tags: [.init(id: "tag-w-15", type: "system", name: "время", description: "")]
      ),
    ]
  }

  static func mocks() -> [Card] {
    [
      mockThesis(),
      mockConcept(),
      mockQuote(),
    ] + mockMorningCards() + mockWorkCards()
  }
}
#endif
