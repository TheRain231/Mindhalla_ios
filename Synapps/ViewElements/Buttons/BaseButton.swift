import SwiftUI

struct BaseButton: View {
  let title: LocalizedStringKey
  let action: () -> Void
  let configuration: Configuration

  init(
    title: LocalizedStringKey,
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
    static func readInCards(_ action: @escaping () -> Void) -> BaseButton {
        Self(
            title: "BaseButton.ReadInCards",
            action: action,
            configuration: .init()
        )
    }

    static func tryAgain(_ action: @escaping () -> Void) -> BaseButton {
        Self(
            title: "BaseButton.TryAgain",
            action: action,
            configuration: .init()
        )
    }
    
    static func downloadAgain(_ action: @escaping () -> Void) -> BaseButton {
        Self(
            title: "BaseButton.DownloadAgain",
            action: action,
            configuration: .init()
        )
    }
}

#Preview {
    BaseButton.tryAgain({})
    BaseButton.downloadAgain({})
}
