import SwiftUI

struct BookLoadingView: View {
    let presentable: Presentable

    var body: some View {
        VStack(alignment: .center, spacing: 50) {
            Text(presentable.title)
                .bookLoadingTitleStyle()
            imageView
            Text(presentable.message)
                .bookLoadingSubtitleStyle()
                .padding()
        }
        .padding()
    }
    
    private var imageView: some View {
        Image("bookLoadingProgress")
            .resizable()
            .scaledToFit()
            .frame(width: 261, height: 261)
            .overlay {
                Image("bookLoading")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
    }
}

extension BookLoadingView {
    struct Presentable {
        var title: String
        let message: String
        
        init(title: String, message: String = "Книга будет преобразована в набор карточек для прочтения. Мы оставим только самое важное для экономии вашего времени") {
            self.title = title
            self.message = message
        }
    }
}

extension BookLoadingView {
    static let `default` = BookLoadingView.Presentable(
        title: "Вычленяем важное...",
        message: "Книга будет преобразована в набор карточек для прочтения. Мы оставим только самое важное для экономии вашего времени"
    )
}

#Preview {
    BookLoadingView(presentable: BookLoadingView.default)
}
