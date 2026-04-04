import Foundation
import SwiftUI

@MainActor @Observable
final class SaveBottomsheetViewModel {
    var isNewSelectionViewPresented: Bool = false
    var searchText: String = ""

    var collections: [QuoteCollection] = QuoteCollection.mocks

    /// Идентификаторы выбранных подборок.
    var selectedIds: Set<String> = []

    var filteredCollections: [QuoteCollection] {
        if searchText.isEmpty {
            return collections
        } else {
            return collections.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    func isSelected(_ collection: QuoteCollection) -> Bool {
        selectedIds.contains(collection.id)
    }

    func toggleSelection(_ collection: QuoteCollection) {
        if selectedIds.contains(collection.id) {
            selectedIds.remove(collection.id)
        } else {
            selectedIds.insert(collection.id)
        }
    }
    
    func addCollection(collection: QuoteCollection) {
        collections.append(collection)
        // TODO: запрос на бек с сохранением подборки / UserDefaults
    }

    func save() {
        // TODO: сохранить карточку в выбранные подборки (selectedIds)
    }
}
