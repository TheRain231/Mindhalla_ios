import SwiftUI

struct BookLoadingSubtitleStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.subheadline)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
  }
}

extension View {
  func bookLoadingSubtitleStyle() -> some View {
    modifier(BookLoadingSubtitleStyle())
  }
}
