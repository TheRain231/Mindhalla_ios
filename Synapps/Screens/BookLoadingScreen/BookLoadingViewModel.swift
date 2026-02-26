import SwiftUI

@MainActor @Observable
final class BookLoadingViewModel {
    private var rotationTask: Task<Void, Never>?
    private var currentMessageIndex: Int = 0

    var currentMessage: String {
        BookLoadingViewModel.messages[currentMessageIndex]
    }

    private let showMessageInterval: TimeInterval = 2.5

    func startTimer() {
        guard rotationTask == nil else { return }
        rotationTask = Task { [showMessageInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(showMessageInterval))
                if Task.isCancelled { break }
                currentMessageIndex = (currentMessageIndex + 1) % BookLoadingViewModel.messages.count
            }
        }
    }

    func stopTimer() {
        rotationTask?.cancel()
        rotationTask = nil
    }
}

extension BookLoadingViewModel {
    static let messages: [String] = [
        "Выжимаем информационный сок",
        "Переводим на человеческий",
        "Листаем 300 страниц",
        "Отделяем факты от воды",
        "Сжимаем главы до тезисов",
        "Подсвечиваем ключевые мысли маркером",
        "Вытаскиваем смысл между строк",
        "Складываем аргументы по полочкам",
        "Моем текст от канцелярита",
        "Перевариваем идеи без потерь вкуса",
        "Переплавляем главы в чек-листы",
        "Находим повторы и вычеркиваем лишнее",
        "Соединяем  мысли в систему",
        "Готовим краткий конспект к подаче",
        "Сканируем цитаты великих"
    ]
}
