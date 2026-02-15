import SwiftUI

struct BookDownloadFailureView: View {
    let presentable: Presentable
    let configuration: Configuration

    var body: some View {
        VStack(alignment: .center, spacing: 73) {
            VStack(spacing: 32) {
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
        .padding()
    }
    
    private var titleLabel: some View {
        Text(presentable.title)
            .bookLoadingTitleStyle()
    }
    
    private var messageLabel: some View {
        Text(presentable.message)
            .bookLoadingSubtitleStyle()
    }
    
    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(
                width: configuration.imageSize.width,
                height: configuration.imageSize.height
            )
    }
    
    private func buttonView(button: BaseButton) -> some View {
        BaseButton(
            title: button.title,
            action: button.action,
            configuration: button.configuration
        )
    }
}

extension BookDownloadFailureView {
    struct Presentable {
        let title: String
        let message: String
        let image: UIImage
        let buttons: [BaseButton]
    }
}

extension BookDownloadFailureView {
    struct Configuration {
        let imageSize: CGSize
        
        static let `default` = Configuration(
            imageSize: CGSize(width: 128, height: 128)
        )
    }
}

#Preview {
    BookDownloadFailureView(
        presentable: BookDownloadFailureView.Presentable(
            title: "Потеряно соединение с интернетом",
            message: "Возможно включен VPN. Выключите его и повтоорите попытку",
            image: UIImage(resource: .tvTowerWithACross),
            buttons: [.tryAgain]
        ),
        configuration: .default
    )
}
