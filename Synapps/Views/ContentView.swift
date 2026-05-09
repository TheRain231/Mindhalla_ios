//
//  ContentView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.viewModelFactory) var factory
  @ObservedObject var viewModel: ViewModel

  var body: some View {
    TabView(selection: $viewModel.selectedTab) {
      HomeView(viewModel: factory.createHomeViewModel(), onOpenSavedByBook: viewModel.openSavedByBook)
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
      ProfileView()
        .tabItem {
          Image(systemName: "person")
          Text(verbatim: "Profile")
        }
        .tag(TabItem.profile)
    }
  }
}

#if DEBUG
#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
#endif
