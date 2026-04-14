import Foundation
import SwiftData
import SwiftUI

struct SaveBottomsheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: SaveBottomsheetViewModel
  @Query(sort: \QuoteCollection.title) var collections: [QuoteCollection]

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 0) {
        Text("SaveBottomsheetScreen.Subtitle")
          .foregroundStyle(.secondary)
          .font(.system(size: 13))
          .padding(.horizontal)
          .padding(.bottom, 10)
        searchField
        newCollectionLink
        List(viewModel.filteredCollections(from: collections)) { collection in
          HStack {
            checkmarkButton(collection: collection)
            Text(collection.title)

            Spacer()

            HStack(spacing: 30) {
              Text(collection.quoteCount.description)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
          }
        }
        .listStyle(.plain)
      }
      .safeAreaInset(edge: .bottom) {
        saveCardButton
      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          closeButton
        }
      }
      .navigationTitle("Save")
      .navigationBarTitleDisplayMode(.large)
      .navigationDestination(for: String.self) { _ in
        NewCollectionBottomsheetView(viewModel: viewModel)
      }
    }
  }
}

extension SaveBottomsheetView {
  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField("search_collection", text: $viewModel.searchText)
        .textFieldStyle(.plain)
    }
    .padding(8)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
    .padding(.top, 4)
  }

  private var newCollectionLink: some View {
    NavigationLink(value: "new_collection") {
      Label("SaveBottomsheetScreen.NewCollection", systemImage: "plus")
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .foregroundStyle(.blue)
    .padding()
  }

  private var closeButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark")
        .foregroundStyle(.black.opacity(0.8))
    }
  }

  private var saveCardButton: some View {
    Button {
      viewModel.save()
      dismiss()
    } label: {
      Text("SaveBottomsheetScreen.SaveCard")
        .blueButtonStyle()
    }
    .padding(.vertical, 8)
    .background(.bar)
  }

  private func checkmarkButton(collection: QuoteCollection) -> some View {
    let isChecked = viewModel.isSelected(collection)
    return Button {
      viewModel.toggleSelection(collection)
    } label: {
      Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
        .foregroundColor(isChecked ? .blue : Color(.systemGray4))
        .padding(.horizontal)
    }
    .buttonStyle(.borderless)
  }
}

#Preview {
  let factory = MockViewModelFactory()

  SaveBottomsheetView(viewModel: factory.createSaveBottomsheetViewModel(card: .mock()))
}
