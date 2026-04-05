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
    @Published var pickerState: PickerState = .collections
    @Published var searchText: String = ""

    init(modelContext: ModelContext) {
      self.modelContext = modelContext
    }

    func delete(_ collection: QuoteCollection) {
      modelContext.delete(collection)
      try? modelContext.save()
    }
  }
}
