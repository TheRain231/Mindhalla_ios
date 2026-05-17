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
          print("[Synapps][onOpenURL] url=\(url.absoluteString) isFileURL=\(url.isFileURL) ext=\(url.pathExtension)")
          if url.isFileURL, url.pathExtension == "synapps" {
            contentViewModel.handleIncomingBundle(url: url)
          } else if url.scheme == "synapps", url.host == "import-pending" {
            contentViewModel.triggerPendingDrain()
          } else {
            contentViewModel.handle(url: url)
          }
        }
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
          SpacedRepetitionScheduler.rescheduleIfNeeded()
        }
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
          contentViewModel.triggerPendingDrain()
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
