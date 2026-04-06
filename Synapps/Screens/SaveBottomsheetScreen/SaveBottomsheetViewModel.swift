import Foundation
import SwiftData
import SwiftUI

@MainActor @Observable
final class SaveBottomsheetViewModel {
  let modelContext: ModelContext
  var isNewCollectionViewPresented: Bool = false
  var searchText: String = ""

  /// Идентификаторы выбранных подборок.
  var selectedIds: Set<String> = []

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func isSelected(_ collection: QuoteCollection) -> Bool {
    selectedIds.contains(collection.id)
  }

  func toggleCollection(_ collection: QuoteCollection) {
    if selectedIds.contains(collection.id) {
      selectedIds.remove(collection.id)
    } else {
      selectedIds.insert(collection.id)
    }
  }

  func saveCollection(collection: QuoteCollection) {
    let collectionId = collection.id
    let predicate = #Predicate<QuoteCollection> { $0.id == collectionId }
    var descriptor: FetchDescriptor<QuoteCollection> = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1

    if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
      modelContext.insert(collection)
      try? modelContext.save()
    }
  }

  func save() {
    // TODO: сохранить карточку в выбранные подборки (selectedIds)
  }
}
