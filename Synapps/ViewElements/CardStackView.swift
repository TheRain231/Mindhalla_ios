//
//  CardStackView.swift
//  Synapps
//

import SwiftUI

/// Shared layout for card stack screens: swiper, optional bottom overlay, gradient background.
struct CardStackView<VM: CardStackViewModel, ItemView: View, Overlay: View>: View {
  @ObservedObject var viewModel: VM
  let onCardSwiped: (SwipeDirection, Int) -> Void
  let content: (VM.Item) -> ItemView
  let overlay: () -> Overlay

  init(
    viewModel: VM,
    onCardSwiped: @escaping (SwipeDirection, Int) -> Void,
    @ViewBuilder content: @escaping (VM.Item) -> ItemView,
    @ViewBuilder overlay: @escaping () -> Overlay
  ) {
    self.viewModel = viewModel
    self.onCardSwiped = onCardSwiped
    self.content = content
    self.overlay = overlay
  }

  var body: some View {
    VStack {
      CardSwiperView(
        cards: viewModel.items,
        onCardSwiped: onCardSwiped,
        currentIndex: $viewModel.topCardIndex
      ) { item in
        content(item)
      }
      .onAppear {
        viewModel.fetch()
      }

      overlay()
    }
    .id(viewModel.viewId)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: CardType.backgroundColors(for: viewModel.topCardTypeForBackground),
        startPoint: .bottom,
        endPoint: .top
      )
    )
    .toolbar(.hidden, for: .tabBar)
  }
}

extension CardStackView where Overlay == EmptyView {
  init(
    viewModel: VM,
    onCardSwiped: @escaping (SwipeDirection, Int) -> Void,
    @ViewBuilder content: @escaping (VM.Item) -> ItemView
  ) {
    self.init(
      viewModel: viewModel,
      onCardSwiped: onCardSwiped,
      content: content,
      overlay: { EmptyView() }
    )
  }
}
