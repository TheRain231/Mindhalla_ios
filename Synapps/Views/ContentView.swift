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
    TabView {
      Tab("Share", systemImage: "circlebadge.2") {}
      Tab("Home", systemImage: "book.closed") {
        HomeView(viewModel: factory.createHomeViewModel())
      }
      Tab("Saved", systemImage: "bookmark") {}
      Tab("Profile", systemImage: "person") {}
    }
  }
}

#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
