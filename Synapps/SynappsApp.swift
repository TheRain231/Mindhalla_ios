//
//  SynappsApp.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftUI

@main
struct SynappsApp: App {
  let viewModelFactory: ViewModelFactoryProtocol

  init() {
    viewModelFactory = MockViewModelFactory()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: viewModelFactory.createContentViewModel())
        .environment(\.viewModelFactory, viewModelFactory)
    }
  }
}

private struct ViewModelFactoryKey: EnvironmentKey {
  static let defaultValue: ViewModelFactoryProtocol = MockViewModelFactory()
}

extension EnvironmentValues {
  var viewModelFactory: ViewModelFactoryProtocol {
    get { self[ViewModelFactoryKey.self] }
    set { self[ViewModelFactoryKey.self] = newValue }
  }
}
