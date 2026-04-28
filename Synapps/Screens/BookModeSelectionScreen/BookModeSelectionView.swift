//
//  BookModeSelectionView.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import SwiftUI

struct BookModeSelectionView: View {
  let bookTitle: String
  let onCardsTap: () -> Void
  let onStudyTap: () -> Void
  let onClose: () -> Void

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(hex: "9B60E9"),
          Color(hex: "6D8DFF"),
          Color(hex: "A9B8FF"),
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
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)

        VStack(spacing: 14) {
          modeButton(
            title: "BookModeSelection.Cards.Title",
            subtitle: "BookModeSelection.Cards.Subtitle",
            icon: "rectangle.stack.fill",
            tint: Color.white
          ) {
            onCardsTap()
          }

          modeButton(
            title: "BookModeSelection.Tasks.Title",
            subtitle: "BookModeSelection.Tasks.Subtitle",
            icon: "checkmark.seal.fill",
            tint: Color(hex: "EDE3FF")
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
          .foregroundStyle(.white.opacity(0.9))
          .frame(width: 34, height: 34)
          .background(.white.opacity(0.15), in: Circle())
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
          .foregroundStyle(Color(hex: "5E31AB"))
          .frame(width: 42, height: 42)
          .background(tint, in: RoundedRectangle(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
          Text(subtitle)
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.85))
            .multilineTextAlignment(.leading)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white.opacity(0.8))
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.white.opacity(0.17), in: RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(.white.opacity(0.2), lineWidth: 1)
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
