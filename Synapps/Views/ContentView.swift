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
      Text(verbatim: "Share")
        .tabItem {
          Image(systemName: "circlebadge.2")
          Text(verbatim: "Share")
        }
        .tag(TabItem.share)
      HomeView(viewModel: factory.createHomeViewModel())
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
      Text(verbatim: "Profile")
        .tabItem {
          Image(systemName: "person")
          Text(verbatim: "Profile")
        }
        .tag(TabItem.profile)
    }
  }
}

#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
