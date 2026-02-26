import SwiftUI

struct BookDownloadStatusView: View {
    let presentable: Presentable
    let configuration: Configuration
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .center, spacing: 73) {
            closeButtonView
            VStack(alignment: configuration.titleAlignment, spacing: 32) {
                titleLabel
                messageLabel
            }
            imageView(presentable.image)
            VStack(alignment: .center) {
                let buttons = presentable.buttons
                ForEach(0..<buttons.count) { index in
                    buttonView(button: buttons[index])
                }
            }
        }
        .padding(configuration.padding)
    }
    
    private var titleLabel: some View {
        Text(presentable.title)
            .bookLoadingTitleStyle()
    }
    
    private var messageLabel: some View {
        Text(presentable.message)
            .bookLoadingSubtitleStyle()
    }

    @ViewBuilder
    private var closeButtonView: some View {
        if configuration.hasDismissButton {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .background(
                            Circle()
                                .foregroundStyle(.black.opacity(0.03))
                                .frame(width: 40, height: 40)
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private func imageView(_ image: UIImage) -> some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(
                    maxWidth: configuration.maxImageWidth,
                    maxHeight: configuration.maxImageHeight
                )
                .shadow(color: configuration.imageShadowColor, radius: configuration.imageShadowRadius)
    }
    
    private func buttonView(button: BaseButton) -> some View {
        BaseButton(
            title: button.title,
            action: button.action,
            configuration: button.configuration
        )
    }
}

extension BookDownloadStatusView {
    struct Presentable {
        let title: String
        let message: String
        let image: UIImage
        let buttons: [BaseButton]
    }
}

extension BookDownloadStatusView {
    struct Configuration {
        let maxImageWidth: CGFloat
        let maxImageHeight: CGFloat
        let imageShadowColor: Color
        let imageShadowRadius: CGFloat
        let titleAlignment: HorizontalAlignment
        let padding: CGFloat
        let hasDismissButton: Bool
        
        init(
            maxImageWidth: CGFloat,
            maxImageHeight: CGFloat,
            imageShadowColor: Color = .clear,
            imageShadowRadius: CGFloat = 0,
            titleAlignment: HorizontalAlignment = .center,
            padding: CGFloat = 8,
            hasDismissButton: Bool = false
        ) {
            self.maxImageWidth = maxImageWidth
            self.maxImageHeight = maxImageHeight
            self.imageShadowColor = imageShadowColor
            self.imageShadowRadius = imageShadowRadius
            self.titleAlignment = titleAlignment
            self.padding = padding
            self.hasDismissButton = hasDismissButton
        }
        
        static let `default` = Configuration(
            maxImageWidth: 128,
            maxImageHeight: 128
        )
        
        static let fullWidthLeftAlignment = Configuration(
            maxImageWidth: .infinity,
            maxImageHeight: .infinity,
            imageShadowColor: .black.opacity(0.3),
            imageShadowRadius: 50,
            titleAlignment: .leading,
            padding: 30,
            hasDismissButton: true
        )
    }
}

extension BookDownloadStatusView.Presentable {
    static func success(onReadCards: @escaping () -> Void) -> Self {
        .init(
            title: "Книга успешно загружена",
            message: "И разбита на...",
            image: UIImage(resource: .bookDownloadSuccess),
            buttons: [BaseButton(title: "Читать в карточках", action: onReadCards)]
        )
    }

    static func processingError(onRetry: @escaping () -> Void) -> Self {
        .init(
            title: "Не удалось обработать книгу",
            message: "Повторите попытку позже или обратитесь в поддержку",
            image: UIImage(resource: .bookPileWithExclamationMark),
            buttons: [BaseButton(title: "Повторить", action: onRetry)]
        )
    }

    static func uploadError(onRetry: @escaping () -> Void) -> Self {
        .init(
            title: "Книга не была загружена",
            message: "Четыре соглашения. Тольтекская книга мудрости не загружена, повторите попытку",
            image: UIImage(resource: .bookWithExclamationMark),
            buttons: [
                BaseButton(
                    title: "Загрузить заново",
                    action: onRetry
                )
            ]
        )
    }

    static func networkError(onRetry: @escaping () -> Void) -> Self {
        .init(
            title: "Потеряно соединение с интернетом",
            message: "Возможно включен VPN. Выключите его и повторите попытку",
            image: UIImage(resource: .tvTowerWithACross),
            buttons: [BaseButton(title: "Повторить", action: onRetry)]
        )
    }
}

#Preview {
    BookDownloadStatusView(
        presentable: BookDownloadStatusView.Presentable(
            title: "Потеряно соединение с интернетом",
            message: "Возможно включен VPN. Выключите его и повторите попытку",
            image: UIImage(resource: .tvTowerWithACross),
            buttons: [.tryAgain]
        ),
        configuration: .default
    )
}

#Preview {
    BookDownloadStatusView(
        presentable: BookDownloadStatusView.Presentable(
            title: "Книга успешно загружена",
            message: "И разбита на...",
            image: UIImage(resource: .bookDownloadSuccess),
            buttons: [BaseButton(
                title: "Читать в карточках",
                action: {},
                configuration: .init()
            )]
        ),
        configuration: .fullWidthLeftAlignment
    )
}
