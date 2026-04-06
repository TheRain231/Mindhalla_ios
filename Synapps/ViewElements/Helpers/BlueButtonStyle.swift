import SwiftUI

struct BlueButtonStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.body)
      .foregroundStyle(.white)
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color.blue)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 16)
  }
}

extension View {
  func blueButtonStyle() -> some View {
    modifier(BlueButtonStyle())
  }
}
