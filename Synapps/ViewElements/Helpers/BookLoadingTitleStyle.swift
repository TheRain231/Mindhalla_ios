import SwiftUI

struct BookLoadingTitleStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.title)
      .multilineTextAlignment(.center)
  }
}

extension View {
  func bookLoadingTitleStyle() -> some View {
    modifier(BookLoadingTitleStyle())
  }
}
