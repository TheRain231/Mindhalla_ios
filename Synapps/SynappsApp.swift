//
//  SynappsApp.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftData
import SwiftUI

@main
struct SynappsApp: App {
  let viewModelFactory: ViewModelFactoryProtocol
  let contentViewModel: ContentView.ViewModel

  init() {
    viewModelFactory = ViewModelFactory()
    contentViewModel = viewModelFactory.createContentViewModel()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: contentViewModel)
        .modelContainer(viewModelFactory.modelContainer)
        .environment(\.viewModelFactory, viewModelFactory)
        .onOpenURL { url in
          contentViewModel.handle(url: url)
        }
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
