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
    case .quote:
      .gray
    case .question:
      .indigo
    case .answer:
      .green
    case .insight:
      .yellow
    case .principle:
      .purple
    case .model:
      .teal
    case .unknown:
      .gray
    }
  }
}

extension Card {
  func sourceDescription() -> String? {
    references.chapterTitle
  }
}

extension Card {
  convenience init(dto: BookCardResponseDTO) {
    let type: CardType = dto.tags.first
      .flatMap { CardType(rawValue: $0.type) } ?? .unknown

    let chapterTitle = dto.references["chapter_title"]?.value as? String
    let pages = dto.references["pages"]?.value as? [Int] ?? []
    let originalTexts = dto.references["original_texts"]?.value as? [String] ?? []
    let references = References(pages: pages, originalTexts: originalTexts, chapterTitle: chapterTitle)

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
    let chapterTitle = dto["chapter_title"] as? String
    self.init(pages: pages, originalTexts: texts, chapterTitle: chapterTitle)
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
          pages: [88, 90],
          originalTexts: ["It is our choices, Harry, that show what we truly are..."],
          chapterTitle: "The Sorting Hat"
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
          pages: [45, 46],
          originalTexts: ["No post on Sundays... except for one peculiar letter."],
          chapterTitle: "The Letters from No One"
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
          pages: [1, 2],
          originalTexts: ["Mr. and Mrs. Dursley of number four..."],
          chapterTitle: "The Boy Who Lived"
        ),
        tags: [
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c91a", type: "system", name: "some-tag-1", description: "some description 1"),
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c912", type: "system", name: "some-tag-2", description: "some description 2"),
          .init(id: "f8f4b3cc-ef8d-46f9-823f-89afae30c913", type: "system", name: "some-tag-3", description: "some description 3"),
        ]
      )
    case .quote:
      Card(
        id: "qt-mock-1",
        type: .quote,
        content: "Не наши способности определяют, кто мы, а наш выбор.",
        references: .init(pages: [92], originalTexts: ["It is our choices, Harry, that show what we truly are..."], chapterTitle: "The Sorting Hat"),
        tags: [.init(id: "qt-tag-1", type: "system", name: "quote", description: "Direct quote from the text")]
      )
    case .question:
      Card(
        id: "q-mock-1",
        type: .question,
        content: "Что показывает наш истинный характер?",
        references: .init(pages: [], originalTexts: [], chapterTitle: "I Является ли любовь искусством?"),
        tags: []
      )
    case .answer:
      Card(
        id: "a-mock-1",
        type: .answer,
        content: "Не наши способности определяют, кто мы, а наш выбор.",
        references: .init(pages: [], originalTexts: [], chapterTitle: "I Является ли любовь искусством?"),
        tags: []
      )
    case .insight:
      Card(
        id: "i-mock-1",
        type: .insight,
        content: "Повторение с интервалами работает лучше, чем один длинный сеанс.",
        references: .init(pages: [54], originalTexts: ["Лучше 15 минут в день, чем 2 часа раз в неделю."], chapterTitle: "II Методы обучения"),
        tags: [.init(id: "i-tag-1", type: "system", name: "learning", description: "Practical learning insight")]
      )
    case .principle:
      Card(
        id: "p-mock-1",
        type: .principle,
        content: "Сначала понимание смысла, затем запоминание деталей.",
        references: .init(pages: [73], originalTexts: ["Принцип: от общего к частному."], chapterTitle: "III Принципы запоминания"),
        tags: [.init(id: "p-tag-1", type: "system", name: "principle", description: "General study principle")]
      )
    case .model:
      Card(
        id: "m-mock-1",
        type: .model,
        content: "Цикл обучения: прочитал -> сформулировал -> применил -> проверил.",
        references: .init(pages: [101], originalTexts: ["Рабочая модель закрепления знаний."], chapterTitle: "IV Модели и frameworks"),
        tags: [.init(id: "m-tag-1", type: "system", name: "framework", description: "Learning model")]
      )
    case .unknown:
      Card(
        id: "0",
        type: .unknown,
        content: "...",
        references: .init(
          pages: [],
          originalTexts: [],
          chapterTitle: nil
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
        references: .init(pages: [1], originalTexts: [], chapterTitle: "I Утреннее намерение"),
        tags: []
      ),
      Card(
        id: "c-2",
        type: .idea,
        content: "Первые минуты после пробуждения задают настрой: не телефон, а одна строка в дневнике.",
        references: .init(pages: [2], originalTexts: [], chapterTitle: "I Утреннее намерение"),
        tags: [.init(id: "tag-c-2", type: "custom", name: "утро", description: "")]
      ),
      Card(
        id: "c-3",
        type: .concept,
        content: "Свет, вода, тишина — три опоры утреннего внимания без лишних стимулов.",
        references: .init(pages: [3], originalTexts: [], chapterTitle: "II Среда для чтения"),
        tags: []
      ),
      Card(
        id: "c-4",
        type: .idea,
        content: "Что сегодня действительно важно — не срочное, а значимое?",
        references: .init(pages: [4], originalTexts: [], chapterTitle: "II Среда для чтения"),
        tags: []
      ),
      Card(
        id: "c-5",
        type: .idea,
        content: "Короткая прогулка или растяжка перед чтением снижают «шум» в голове и помогают лучше запоминать смысл, а не отдельные фразы.",
        references: .init(pages: [5], originalTexts: [], chapterTitle: "III Тело и внимание"),
        tags: []
      ),
      Card(
        id: "c-6",
        type: .thesis,
        content: "Чтение утром — это не про количество страниц, а про ясность: одна идея, которую можно применить до обеда, ценнее десяти забытых абзацев.",
        references: .init(pages: [6, 7], originalTexts: [], chapterTitle: "III Тело и внимание"),
        tags: []
      ),
      Card(
        id: "c-7",
        type: .idea,
        content: "Заметка.",
        references: .init(pages: [8], originalTexts: [], chapterTitle: "IV Фиксация мысли"),
        tags: []
      ),
      Card(
        id: "c-8",
        type: .concept,
        content: "Если вчерашний день закончился на раздражении, утреннее чтение можно начать с короткого списка благодарностей — не как ритуал «для галочки», а как способ сместить фокус с оценки себя на наблюдение за тем, что уже есть и что можно бережно развить.",
        references: .init(pages: [9, 10], originalTexts: [], chapterTitle: "IV Фиксация мысли"),
        tags: []
      ),
      Card(
        id: "c-9",
        type: .concept,
        content: "Какую одну мысль из прочитанного я хочу проверить в действии сегодня — и как пойму, что эксперимент удался?",
        references: .init(pages: [11], originalTexts: [], chapterTitle: "V Применение"),
        tags: []
      ),
      Card(
        id: "c-10",
        type: .thesis,
        content: "Утреннее чтение связывает «кто я хочу быть» с «что я делаю в первый час»: не геройством, а маленькой последовательностью — открыть книгу, прочитать абзац, записать вывод. Так день начинается не из тревоги списка дел, а из выбранного смысла, который потом проще переносить в работу, отношения и отдых без чувства, что жизнь распалась на несовместимые куски.",
        references: .init(pages: [12, 13, 14], originalTexts: [], chapterTitle: "V Применение"),
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
        references: .init(pages: [20], originalTexts: [], chapterTitle: "I Фокус и приоритеты"),
        tags: [.init(id: "tag-w-11", type: "custom", name: "фокус", description: "")]
      ),
      Card(
        id: "c-12",
        type: .idea,
        content: "Нет.",
        references: .init(pages: [21], originalTexts: [], chapterTitle: "I Фокус и приоритеты"),
        tags: []
      ),
      Card(
        id: "c-13",
        type: .concept,
        content: "Разбей большую задачу на шаги по 25 минут: после каждого блока — одна строка в логе, что изменилось в понимании проблемы, а не только в объёме сделанного.",
        references: .init(pages: [22, 23], originalTexts: [], chapterTitle: "II Глубокая работа"),
        tags: []
      ),
      Card(
        id: "c-14",
        type: .thesis,
        content: "Кому нужен этот отчёт через месяц — тебе, команде или формальности? От ответа зависит глубина анализа и границы «достаточно хорошо».",
        references: .init(pages: [24], originalTexts: [], chapterTitle: "II Глубокая работа"),
        tags: []
      ),
      Card(
        id: "c-15",
        type: .idea,
        content: "Когда встречи съедают день, оставь два окна без календаря: одно — для глубокой работы с одним документом, другое — для разбора входящих без немедленных ответов. Так ты возвращаешь инициативу: не поток уведомлений решает, что важно, а заранее выбранный приоритет, к которому можно вернуться после шума, не теряя нить рассуждений и не превращая вечер в догоняние задач, которые утром казались мелочами.",
        references: .init(pages: [25, 26, 27], originalTexts: [], chapterTitle: "III Управление временем"),
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
