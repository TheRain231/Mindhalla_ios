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
    @Published var showAddBookModal: Bool = false
    var onAddBookCompletion: (Result<URL, Error>) -> Void

    init(networkManager: NetworkManagerProtocol) {
      self.networkManager = networkManager
      self.onAddBookCompletion = { result in
        switch result {
        case let .success(url):
          Task {
            do {
              let uploadResult = try await networkManager.uploadBook(url)
              print(uploadResult) // TODO: Поменять на алерт или что-нибудь
              await MainActor.run {
                // TODO: После успешной загрузки обновляем список книг
              }
            } catch {
              // TODO: добавить обработку ошибок
              print("Ошибка загрузки файла: \(error)")
            }
          }
        default:
          break
        }
      }

      self.books = [] // обязательно вызывать fetch на onAppear
    }

    func fetch() {
      Task {
        do {
          let fetchedBooks = try await networkManager.getAllBooks()
          await MainActor.run {
            self.books = fetchedBooks // TODO: Надо разобраться и исправить warning
          }
        } catch {
          // TODO: добавить обработку ошибок
          print(error)
        }
      }
    }

    func addBookAction() {
      showAddBookModal = true
    }
  }
}
