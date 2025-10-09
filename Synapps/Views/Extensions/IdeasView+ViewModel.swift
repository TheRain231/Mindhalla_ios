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

    init(ideas: [Idea]) {
      self.ideas = ideas
    }
  }
}
