//
//  CardSwipeView.swift
//  Synapps
//
//  Created by Andrey Stepanov on 03.10.2025.
//

import SwiftUI

enum SwipeDirection {
  case left, right, undefined
}

public struct CardSwiperView<Item, Content: View>: View {
  var ideas: [Item]

  let contentBuilder: (Item) -> Content

  var onCardSwiped: ((SwipeDirection, Int) -> Void)?
  var onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)?
  var initialOffsetY: CGFloat = 5
  var initialRotationAngle: Double = 0.5

  @State var currentIndex: Int = 0 {
    didSet {
      currentIndexBinding = currentIndex
    }
  }

  @Binding private var currentIndexBinding: Int

  init(
    ideas: [Item],
    onCardSwiped: ((SwipeDirection, Int) -> Void)? = nil,
    onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)? = nil,
    initialOffsetY: CGFloat = 5,
    initialRotationAngle: Double = 0.5,
    currentIndex currentIndexBinding: Binding<Int>? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.ideas = ideas
    self.onCardSwiped = onCardSwiped
    self.onCardDragged = onCardDragged
    self.initialOffsetY = initialOffsetY
    self.initialRotationAngle = initialRotationAngle
    self.contentBuilder = content
    self._currentIndexBinding = currentIndexBinding ?? .constant(0)
  }

  public var body: some View {
    ZStack {
      ForEach(ideas.indices, id: \.self) { index in
        CardView(
          index: index,
          onCardSwiped: { swipeDirection in
            onCardSwiped?(swipeDirection, index)
            if swipeDirection != .undefined {
              currentIndex -= 1
            }
          },
          onCardDragged: { direction, index, offset in
            onCardDragged?(direction, index, offset)
          },
          content: {
            contentBuilder(ideas[index])
          },
          initialOffsetY: initialOffsetY,
          initialRotationAngle: initialRotationAngle,
          zIndex: Double(ideas.count - index)
        )
      }
    }.onAppear {
      currentIndex = ideas.count - 1
    }
  }

  private struct CardView<CardContent: View>: View {
    let id = UUID()
    var index: Int
    var onCardSwiped: ((SwipeDirection) -> Void)?
    var onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)?
    var content: () -> CardContent
    var initialOffsetY: CGFloat
    var initialRotationAngle: Double
    var zIndex: Double

    @State private var offset = CGSize.zero
    @State private var overlayColor: Color = .clear
    @State private var isRemoved = false
    @State private var activeCardIndex: Int?

    var body: some View {
      ZStack {
        content()
          .frame(width: 320, height: 420)
          .offset(x: offset.width * 1, y: offset.height * 0.3)
          .rotationEffect(.degrees(Double(offset.width / 40)))
          .zIndex(zIndex)

        Rectangle()
          .foregroundColor(overlayColor)
          .opacity(isRemoved ? 0 : (activeCardIndex == index ? 1 : 0))
          .frame(width: 320, height: 420)
          .cornerRadius(10)
          .blendMode(.overlay)
      }
      .gesture(
        DragGesture()
          .onChanged { gesture in
            offset = gesture.translation
            activeCardIndex = index
            withAnimation {
              handleCardDragging(offset)
            }
          }
          .onEnded { _ in
            withAnimation {
              handleSwipe(offsetWidth: offset.width, offsetHeight: offset.height)
            }
          }
      )
      .opacity(isRemoved ? 0 : 1)
    }

    func handleCardDragging(_ offset: CGSize) {
      var swipeDirection: SwipeDirection = .undefined

      switch (offset.width, offset.height) {
      case (-500...(-150), _):
        swipeDirection = .left
      case (150...500, _):
        swipeDirection = .right
      case (_, _):
        swipeDirection = .undefined
      }

      onCardDragged?(swipeDirection, index, offset)
    }

    func handleSwipe(offsetWidth: CGFloat, offsetHeight: CGFloat) {
      var swipeDirection: SwipeDirection

      switch (offsetWidth, offsetHeight) {
      case (-500...(-150), _):
        swipeDirection = .left
        offset = CGSize(width: -350, height: 0)
        isRemoved = true
      case (150...500, _):
        swipeDirection = .right
        offset = CGSize(width: 350, height: 0)
        isRemoved = true
      default:
        swipeDirection = .undefined
        offset = .zero
        overlayColor = .clear
      }

      onCardSwiped?(swipeDirection)
    }
  }
}
