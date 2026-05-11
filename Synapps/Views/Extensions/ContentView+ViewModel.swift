//
//  ContentView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import SwiftUI

extension ContentView {
  final class ViewModel: ObservableObject {
    @Published var selectedTab: TabItem = .home
    @Published var deepLink: DeepLink?

    func handle(url: URL) {
      guard let link = DeepLink(url: url) else { return }
      deepLink = link
      selectedTab = .saved
    }

    func openSavedByBook(bookId: String) {
      deepLink = .savedByBook(bookId: bookId)
      selectedTab = .saved
    }
  }
}

enum TabItem {
  case home
  case saved
  case mindmaps
  case profile
}
