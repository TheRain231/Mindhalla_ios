import Foundation

struct FlashCard: Identifiable {
  let id: String
  let question: String
  let answer: String
    let isQuestionVisible: Bool = true
}

extension FlashCard {
    var type: CardType {
        isQuestionVisible ? .question : .answer
    }
}

#if DEBUG
extension FlashCard {
  static func mocks() -> [FlashCard] {
    [
      FlashCard(
        id: "fc-1",
        question: "Что показывает наш истинный характер, по мнению Дамблдора?",
        answer: "Не наши способности определяют, кто мы, а наш выбор."
      ),
      FlashCard(
        id: "fc-2",
        question: "Какой совет даёт Дамблдор относительно мечтаний?",
        answer: "Нельзя жить в мечтах и забывать о реальной жизни."
      ),
      FlashCard(
        id: "fc-3",
        question: "Что Дамблдор говорит о смерти?",
        answer: "Для хорошо организованного ума смерть — всего лишь очередное приключение."
      ),
      FlashCard(
        id: "fc-4",
        question: "Какая сила, по мнению Дамблдора, сильнее любой магии?",
        answer: "Любовь — самая могущественная сила, которая защищает даже без заклинаний."
      ),
      FlashCard(
        id: "fc-5",
        question: "Что нужно делать, чтобы обрести счастье, по Дамблдору?",
        answer: "Счастье можно найти даже в самые тёмные времена, если не забывать обращаться к свету."
      ),
      FlashCard(
        id: "fc-6",
        question: "Почему важна правда, а не то, что о ней говорят?",
        answer: "Правда — прекрасная и ужасная вещь, к которой надо относиться с осторожностью."
      ),
      FlashCard(
        id: "fc-7",
        question: "Что говорит Хагрид о настоящей дружбе?",
        answer: "Настоящий друг — тот, кто приходит, когда весь мир уходит."
      ),
    ]
  }
}
#endif
