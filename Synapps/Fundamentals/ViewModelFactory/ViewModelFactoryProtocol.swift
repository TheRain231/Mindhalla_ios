//
//  ViewModelFactoryProtocol.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import SwiftUI

protocol ViewModelFactoryProtocol: AnyObject {
  func createContentViewModel() -> ContentView.ViewModel
  func createCardsViewModel(cardID: String) -> CardsView.ViewModel
  func createHomeViewModel() -> HomeView.ViewModel
}
