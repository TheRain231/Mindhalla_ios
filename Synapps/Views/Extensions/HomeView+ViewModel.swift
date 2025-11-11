//
//  HomeView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftUI

extension HomeView {
  final class ViewModel: ObservableObject {
    let networkManager: NetworkManagerProtocol

    @Published var books: [BookMetaResponse]

    init(networkManager: NetworkManagerProtocol) {
      self.networkManager = networkManager

      self.books = [] // обязательно вызывать fetch на onAppear
    }

    func fetch() {
      Task { @MainActor in
        do {
          let fetchedBooks = try await networkManager.getAllBooks()
          self.books = fetchedBooks
        } catch {
          // TODO: добавить обработку ошибок
          print(error)
        }
      }
    }
  }
}
