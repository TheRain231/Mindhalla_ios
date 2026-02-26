import SwiftUI

struct BaseButton: View {
    let title: String
    let action: () -> Void
    let configuration: Configuration
    
    init(
        title: String,
        action: @escaping () -> Void,
        configuration: Configuration = .init()
    ) {
        self.title = title
        self.action = action
        self.configuration = configuration
    }

    var body: some View {
        Button(title, action: action)
            .bold()
            .foregroundStyle(.primary)
            .frame(width: configuration.width, height: configuration.height)
            .background(.thinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .padding()
    }
}

extension BaseButton {
    struct Configuration {
        let height: CGFloat
        let width: CGFloat
        
        init(
            height: CGFloat = 40,
            width: CGFloat = 322
        ) {
            self.height = height
            self.width = width
        }
    }
}

extension BaseButton {
    static let tryAgain: BaseButton = .init(
        title: "Повторить",
        action: { },
        configuration: .init()
    )
    
    static let downloadAgain: BaseButton = .init(
        title: "Загрузить заново",
        action: { },
        configuration: .init()
    )
}

#Preview {
    BaseButton.tryAgain
    BaseButton.downloadAgain
}

