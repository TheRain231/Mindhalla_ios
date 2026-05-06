import SwiftUI

struct BookModeSelectionView: View {
  let bookTitle: String
  let onCardsTap: () -> Void
  let onStudyTap: () -> Void
  let onClose: () -> Void

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      LinearGradient(
        colors: [
          Color(hex: "9B60E9").opacity(0.22),
          Color(hex: "9B60E9").opacity(0.08),
          .clear,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 20) {
        topBar
        Spacer()

        Text("BookModeSelection.Title")
          .font(.system(size: 34, weight: .bold))
          .foregroundStyle(.primary)

        Text(bookTitle)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(2)

        VStack(spacing: 14) {
          modeButton(
            title: "BookModeSelection.Cards.Title",
            subtitle: "BookModeSelection.Cards.Subtitle",
            icon: "rectangle.stack.fill",
            tint: Color(hex: "9B60E9").opacity(0.14)
          ) {
            onCardsTap()
          }

          modeButton(
            title: "BookModeSelection.Tasks.Title",
            subtitle: "BookModeSelection.Tasks.Subtitle",
            icon: "checkmark.seal.fill",
            tint: Color(hex: "9B60E9").opacity(0.2)
          ) {
            onStudyTap()
          }
        }
        Spacer()
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.bottom, UIScreen.main.bounds.height * 0.18)
    }
  }

  private var topBar: some View {
    HStack {
      Spacer()
      Button {
        onClose()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.secondary)
          .frame(width: 34, height: 34)
          .background(Color(.secondarySystemGroupedBackground), in: Circle())
      }
      .buttonStyle(.plain)
    }
  }

  private func modeButton(
    title: LocalizedStringKey,
    subtitle: LocalizedStringKey,
    icon: String,
    tint: Color,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(hex: "9B60E9"))
          .frame(width: 42, height: 42)
          .background(tint, in: RoundedRectangle(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color(hex: "9B60E9"))
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(Color(hex: "9B60E9").opacity(0.12), lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}

#if DEBUG
#Preview {
  BookModeSelectionView(
    bookTitle: "Atomic Habits",
    onCardsTap: {},
    onStudyTap: {},
    onClose: {}
  )
}
#endif
