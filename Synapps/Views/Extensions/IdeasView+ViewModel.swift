//
//  IdeasView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 02.10.2025.
//

import SwiftUI

extension IdeasView {
  final class ViewModel: ObservableObject {
    @Published var ideas: [Idea]
    @Published var topCardIndex: Int

    init(ideas: [Idea]) {
      self.ideas = ideas
      topCardIndex = ideas.count - 1
    }

    var topCard: Idea? {
      ideas[topCardIndex]
    }
  }
}
