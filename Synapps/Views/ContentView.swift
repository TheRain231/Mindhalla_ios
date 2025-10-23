//
//  ContentView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: ViewModel

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
  }
}

#Preview {
  ContentView(viewModel: MockViewModelFactory().createContentViewModel())
}
