import Foundation
import SwiftUI

struct NewSelectionBottomsheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: SaveBottomsheetViewModel
    @State private var selectionTitle: String = ""
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            textField
            saveButton
        }
        .navigationTitle("SaveBottomsheetScreen.NewSelection")
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
            Text("NewSelectionBottomsheetScreen.SaveSelection")
                .blueButtonStyle()
        }
        .disabled(selectionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var textField: some View {
        TextField(
            "NewSelectionBottomsheet.SelectionTitle",
            text: $selectionTitle
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
        let trimmed = selectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let collection = QuoteCollection(title: trimmed)
        viewModel.addCollection(collection: collection)
        dismiss()
    }
}

#Preview {
    NewSelectionBottomsheetView(viewModel: SaveBottomsheetViewModel())
}
