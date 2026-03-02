import SwiftUI

struct BookLoadingContainer: View {
  let viewModel: BookLoadingViewModel

  private var presentable: BookLoadingView.Presentable {
    BookLoadingView.Presentable(title: viewModel.currentMessage)
  }

  var body: some View {
    BookLoadingView(presentable: presentable)
      .onAppear { viewModel.startTimer() }
      .onDisappear { viewModel.stopTimer() }
  }
}
