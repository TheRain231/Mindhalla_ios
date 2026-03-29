//
//  HomeView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 14.10.2025.
//

import SwiftData
import SwiftUI

struct HomeView: View {
  @StateObject var viewModel: ViewModel
  @Environment(\.viewModelFactory) var factory
  @Query private var books: [BookMetaResponse]
  @State private var bookLoadingViewModel = BookLoadingViewModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(books) { book in
            NavigationLink(value: book) {
              BookOverview(book: book)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
      .fileImporter(isPresented: $viewModel.showAddBookModal, allowedContentTypes: [.pdf], onCompletion: viewModel.onAddBookCompletion)
      .alert("Доступ к файлам", isPresented: $viewModel.showFileAccessAlert) {
        Button("Разрешить") {
          viewModel.confirmFileAccessAndOpenPicker()
        }
        Button("Не сейчас", role: .cancel) {
          viewModel.declineFileAccess()
        }
      } message: {
        Text("Чтобы добавить книгу, нужно выбрать PDF-файл с устройства. Разрешить доступ к файлам?")
      }
      .fullScreenCover(item: $viewModel.uploadState) { state in
        switch state {
        case .loading:
          BookLoadingContainer(viewModel: bookLoadingViewModel)
        case .success:
          BookDownloadStatusView(
            presentable: .success(onReadCards: { // go to cards
            }),
            configuration: .fullWidthLeftAlignment
          )
        case .processingError:
          BookDownloadStatusView(
            presentable: .processingError(onRetry: { viewModel.retryUpload() }),
            configuration: .default
          )
        case .uploadError:
          BookDownloadStatusView(
            presentable: .uploadError(onRetry: { viewModel.retryUpload() }),
            configuration: .default
          )
        case .networkError:
          BookDownloadStatusView(
            presentable: .networkError(onRetry: { viewModel.retryUpload() }),
            configuration: .default
          )
        }
      }
      .navigationTitle("my_books")
      .navigationDestination(for: BookMetaResponse.self) { book in
        CardsView(viewModel: factory.createCardsViewModel(cardID: book.id))
          .ignoresSafeArea()
      }
      .navigationDestination(for: QuizDestination.self) { _ in
        QuizView(viewModel: factory.createQuizViewModel())
          .ignoresSafeArea()
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if viewModel.isLoading {
            ProgressView()
              .progressViewStyle(.circular)
          } else {
            Button {
              viewModel.addBookAction()
            } label: {
              Image(systemName: "plus")
            }
          }
        }
      }
      .task(id: viewModel.loadTrigger) {
        await viewModel.fetch()
      }
      .refreshable {
        viewModel.reload()
      }
    }
  }
}

#Preview {
  let factory = MockViewModelFactory()

  HomeView(viewModel: factory.createHomeViewModel())
    .modelContainer(factory.modelContainer)
}
