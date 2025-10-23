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
  }
}

enum TabItem {
  case share
  case home
  case saved
  case profile
}
