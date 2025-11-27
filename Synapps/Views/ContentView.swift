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
      Text("Share")
        .tabItem {
          Image(systemName: "circlebadge.2")
          Text("Share")
        }
        .tag(TabItem.share)
      HomeView(viewModel: factory.createHomeViewModel())
        .tabItem {
          Image(systemName: "book.closed")
          Text("Home")
        }
        .tag(TabItem.home)
      Text("Saved")
        .tabItem {
          Image(systemName: "bookmark")
          Text("Saved")
        }
        .tag(TabItem.saved)
      Text("Profile")
        .tabItem {
          Image(systemName: "person")
          Text("Profile")
        }
        .tag(TabItem.profile)
    }
  }
}

#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
