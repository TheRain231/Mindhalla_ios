import SwiftUI

struct BaseButton: View {
    let title: String
    let action: () -> Void
    let configuration: Configuration

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
    }
}

extension BaseButton {
    static let tryAgain: BaseButton = .init(
        title: "Повторить",
        action: { },
        configuration: .init(height: 40, width: 322)
    )
    
    static let downloadAgain: BaseButton = .init(
        title: "Загрузить заново",
        action: { },
        configuration: .init(height: 40, width: 322)
    )
}

#Preview {
    BaseButton.tryAgain
    BaseButton.downloadAgain
}

