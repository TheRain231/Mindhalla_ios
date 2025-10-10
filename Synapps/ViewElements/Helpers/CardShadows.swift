//
//  CardShadows.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import SwiftUI

struct CardShadows: ViewModifier {
  func body(content: Content) -> some View {
    content
      .shadow(color: .black.opacity(0.07), radius: 20, y: 4)
      .shadow(color: .black.opacity(0.16), radius: 2)
  }
}

extension View {
  func cardShadow() -> some View {
    modifier(CardShadows())
  }
}
