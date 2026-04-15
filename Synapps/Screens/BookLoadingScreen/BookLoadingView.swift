import Lottie
import SwiftUI

struct BookLoadingView: View {
  let presentable: Presentable

  var body: some View {
    VStack(alignment: .center, spacing: 50) {
      Text(presentable.title)
        .bookLoadingTitleStyle()
      LottieView(animation: .named("BookLoadingAnimation"))
        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
      Text(presentable.message)
        .bookLoadingSubtitleStyle()
        .padding()
    }
    .padding()
  }
}

extension BookLoadingView {
  struct Presentable {
    var title: LocalizedStringKey
    let message: LocalizedStringKey

    init(
      title: LocalizedStringKey,
      message: LocalizedStringKey = Localized.defaultLoadingMessage
    ) {
      self.title = title
      self.message = message
    }
  }
}

extension BookLoadingView {
  static let `default` = BookLoadingView.Presentable(
    title: Localized.defaultLoadingTitle,
    message: Localized.defaultLoadingMessage
  )
}

extension BookLoadingView {
  private enum Localized {
    static let defaultLoadingTitle = LocalizedStringKey("Loading.DefaultTitle")
    static let defaultLoadingMessage = LocalizedStringKey("Loading.DefaultMessage")
  }
}

#Preview {
  BookLoadingView(presentable: BookLoadingView.default)
}
