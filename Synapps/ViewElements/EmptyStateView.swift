//
//  EmptyStateView.swift
//  Synapps
//

import SwiftUI

struct EmptyStateView: View {
  let icon: String
  let title: LocalizedStringKey
  var message: LocalizedStringKey? = nil

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 48, weight: .light))
        .foregroundStyle(Color(.systemGray3))
      Text(title)
        .font(.title3.weight(.semibold))
        .foregroundStyle(.primary)
      if let message {
        Text(message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 60)
  }
}
