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

  private func imageView(_ image: Image) -> some View {
    image
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
    let image: Image
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
      title: Localized.successLoadingTitle,
      message: Localized.successLoadingMessage,
      image: Image(.bookDownloadSuccess),
      buttons: [.readInCards(onReadCards)]
    )
  }

  static func processingError(onRetry: @escaping () -> Void) -> Self {
    .init(
        title: Localized.processingErrorTitle,
      message: Localized.processingErrorMessage,
      image: Image(.bookPileWithExclamationMark),
        buttons: [.tryAgain(onRetry)]
    )
  }

  static func uploadError(onRetry: @escaping () -> Void) -> Self {
    .init(
        title: Localized.uploadErrorTitle,
      message: Localized.uploadErrorMessage,
      image: Image(.bookWithExclamationMark),
      buttons: [.downloadAgain(onRetry)]
    )
  }

  static func networkError(onRetry: @escaping () -> Void) -> Self {
    .init(
        title: Localized.networkErrorTitle,
      message: Localized.networkErrorMessage,
      image: Image(.tvTowerWithACross),
        buttons: [.tryAgain(onRetry)]
    )
  }
}

extension BookDownloadStatusView.Presentable {
    private enum Localized {
        static let successLoadingTitle = NSLocalizedString(
            "Loading.Success.Title",
            comment: "Loading. Успешная загрузка книги. Заголовок"
        )

        static let successLoadingMessage = NSLocalizedString(
            "Loading.Success.Subtitle",
            comment: "Loading. Успешная загрузка книги. Подзаголовок"
        )

        static let processingErrorTitle = NSLocalizedString(
            "Loading.Error.Processing.Title",
            comment: "Loading. Ошибка декодирования при загрузке книги. Заголовок"
        )

        static let processingErrorMessage = NSLocalizedString(
            "Loading.Error.Processing.Subtitle",
            comment: "Loading. Ошибка декодирования при загрузке книги. Подзаголовок"
        )

        static let uploadErrorTitle = NSLocalizedString(
            "Loading.Error.Upload.Title",
            comment: "Loading. Общая ошибка загрузки книги. Заголовок"
        )

        static let uploadErrorMessage = NSLocalizedString(
            "Loading.Error.Upload.Subtitle",
            comment: "Loading. Общая ошибка загрузки книги. Подзаголовок"
        )

        static let networkErrorTitle = NSLocalizedString(
            "Loading.Error.Network.Title",
            comment: "Loading. Ошибка сети при загрузке книги. Заголовок"
        )

        static let networkErrorMessage = NSLocalizedString(
            "Loading.Error.Network.Subtitle",
            comment: "Loading. Ошибка сети при загрузке книги. Подзаголовок"
        )
        
    }
}

#Preview {
  BookDownloadStatusView(
    presentable: BookDownloadStatusView.Presentable(
      title: "Потеряно соединение с интернетом",
      message: "Возможно включен VPN. Выключите его и повторите попытку",
      image: Image(.tvTowerWithACross),
      buttons: [.tryAgain({})]
    ),
    configuration: .default
  )
}

#Preview {
  BookDownloadStatusView(
    presentable: BookDownloadStatusView.Presentable(
      title: "Книга успешно загружена",
      message: "И разбита на...",
      image: Image(.bookDownloadSuccess),
      buttons: [BaseButton(
        title: "Читать в карточках",
        action: {},
        configuration: .init()
      )]
    ),
    configuration: .fullWidthLeftAlignment
  )
}
