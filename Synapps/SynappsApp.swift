//
//  SynappsApp.swift
//  Synapps
//
//  Created by Andrey Stepanov on 08.09.2025.
//

import SwiftData
import SwiftUI
import UserNotifications

#if DEBUG
import Atlantis
#endif

@main
struct SynappsApp: App {
  let viewModelFactory: ViewModelFactoryProtocol
  let contentViewModel: ContentView.ViewModel

  init() {
    #if DEBUG
    Atlantis.start()
    #endif

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
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
          SpacedRepetitionScheduler.rescheduleIfNeeded()
        }
    }
  }
}

private struct ViewModelFactoryKey: EnvironmentKey {
  #if DEBUG
  static let defaultValue: ViewModelFactoryProtocol = MockViewModelFactory()
  #else
  static let defaultValue: ViewModelFactoryProtocol = ViewModelFactory()
  #endif
}

extension EnvironmentValues {
  var viewModelFactory: ViewModelFactoryProtocol {
    get { self[ViewModelFactoryKey.self] }
    set { self[ViewModelFactoryKey.self] = newValue }
  }
}
