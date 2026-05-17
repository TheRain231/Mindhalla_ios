//
//  ContentView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.viewModelFactory) var factory
  @Environment(\.modelContext) private var modelContext
  @ObservedObject var viewModel: ViewModel

  var body: some View {
    TabView(selection: $viewModel.selectedTab) {
      HomeView(
        viewModel: factory.createHomeViewModel(),
        onOpenSavedByBook: viewModel.openSavedByBook,
        pendingDrainToken: viewModel.pendingDrainToken
      )
        .tabItem {
          Image(systemName: "book.closed")
          Text("my_books")
        }
        .tag(TabItem.home)
      SavedView(viewModel: factory.createSavedViewModel(), deepLink: $viewModel.deepLink)
        .tabItem {
          Image(systemName: "bookmark")
          Text("saved_books")
        }
        .tag(TabItem.saved)
      MindMapsView(viewModel: factory.createMindMapsViewModel())
        .tabItem {
          Image(systemName: "brain")
          Text("mind_maps")
        }
        .tag(TabItem.mindmaps)
      ProfileView()
        .tabItem {
          Image(systemName: "person")
          Text(verbatim: "Profile")
        }
        .tag(TabItem.profile)
    }
    .onChange(of: viewModel.incomingBundleURL) { _, url in
      guard let url else { return }
      viewModel.performImport(url: url, modelContext: modelContext)
    }
    .overlay(alignment: .top) {
      if let message = viewModel.lastImportMessage {
        ImportToast(message: message)
          .padding(.top, 8)
          .transition(.move(edge: .top).combined(with: .opacity))
          .task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
              withAnimation { viewModel.lastImportMessage = nil }
            }
          }
      }
    }
    .alert(item: $viewModel.importError) { err in
      Alert(
        title: Text("Import.Error.Title"),
        message: Text(err.errorDescription ?? ""),
        dismissButton: .default(Text("OK"))
      )
    }
  }
}

private struct ImportToast: View {
  let message: String

  var body: some View {
    Text(message)
      .font(.callout.weight(.medium))
      .foregroundStyle(.white)
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .background(Capsule().fill(Color.black.opacity(0.85)))
      .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
  }
}

#if DEBUG
#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
#endif
