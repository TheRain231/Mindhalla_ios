import Foundation
import SwiftUI

struct NewCollectionBottomsheetView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var viewModel: SaveBottomsheetViewModel
  @State private var collectionTitle: String = ""
  @FocusState private var fieldIsFocused: Bool

  var body: some View {
    VStack(spacing: 12) {
      Spacer(minLength: 0)
      textField
      saveButton
    }
    .navigationTitle("SaveBottomsheetScreen.NewCollection")
    .navigationBarTitleDisplayMode(.inline)
    .padding(.bottom, 8)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark")
            .foregroundStyle(.black.opacity(0.8))
        }
      }
    }
    .onAppear {
      fieldIsFocused = true
    }
  }

  private var saveButton: some View {
    Button {
      submitNewCollection()
    } label: {
      Text("NewCollectionBottomsheetScreen.SaveCollection")
        .blueButtonStyle()
    }
    .disabled(collectionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }

  private var textField: some View {
    TextField(
      "NewCollectionBottomsheet.CollectionTitle",
      text: $collectionTitle,
      axis: .vertical
    )
    .focused($fieldIsFocused)
    .onSubmit {
      submitNewCollection()
    }
    .padding()
    .background(.thinMaterial)
    .cornerRadius(16)
    .padding(.horizontal)
  }

  private func submitNewCollection() {
    let trimmed = collectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    let collection = QuoteCollection(title: trimmed)
    viewModel.saveCollection(collection: collection)
    dismiss()
  }
}

#if DEBUG
#Preview {
  let factory = MockViewModelFactory()

  NewCollectionBottomsheetView(viewModel: factory.createSaveBottomsheetViewModel(card: .mock()))
}
#endif
