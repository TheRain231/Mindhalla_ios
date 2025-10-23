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
      Tab("Share", systemImage: "circlebadge.2", value: .share) {}
      Tab("Home", systemImage: "book.closed", value: .home) {
        HomeView(viewModel: factory.createHomeViewModel())
      }
      Tab("Saved", systemImage: "bookmark", value: .saved) {}
      Tab("Profile", systemImage: "person", value: .profile) {}
    }
  }
}

#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
