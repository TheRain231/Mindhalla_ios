//
//  SavedView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 25.12.2025.
//

import SwiftData
import SwiftUI

extension SavedView {
  final class ViewModel: ObservableObject {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
      self.modelContext = modelContext
    }
  }
}
