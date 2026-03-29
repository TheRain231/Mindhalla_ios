import Foundation
import SwiftUI

struct SaveBottomsheetView: View {
    @State private var searchText: String = ""
    let items = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]
    
    var filteredItems: [String] {
            if searchText.isEmpty {
                return items
            } else {
                return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    
    var body: some View {
        NavigationStack {
            List(filteredItems, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("Save")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "search_selection"
            )
            .listStyle(.plain)
        }
    }
}

#Preview {
    SaveBottomsheetView()
}
