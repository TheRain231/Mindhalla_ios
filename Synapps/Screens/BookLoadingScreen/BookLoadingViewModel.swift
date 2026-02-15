import SwiftUI

@MainActor @Observable
final class BookLoadingViewModel {
    var timer: Timer?
    var currentMessage: String {
        BookLoadingViewModel.messages[currentMessageIndex]
    }

    private let showMessageInterval: TimeInterval = 2.5
    private var currentMessageIndex: Int = 0

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: showMessageInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentMessageIndex = (self.currentMessageIndex + 1) % BookLoadingViewModel.messages.count
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
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
