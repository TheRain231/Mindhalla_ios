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
  private var cards: [Item]

  private let contentBuilder: (Item) -> Content

  private var onCardSwiped: ((SwipeDirection, Int) -> Void)?
  private var onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)?
  private var visibleCardsCount: Int = 2
  private var initialOffsetY: CGFloat = 5
  private var initialRotationAngle: Double = 0.5

  @State private var activeCardIndex: Int?
  @State private var currentIndex: Int = 0 {
    didSet {
      currentIndexBinding = currentIndex
    }
  }

  @Binding var currentIndexBinding: Int

  init(
    cards: [Item],
    onCardSwiped: ((SwipeDirection, Int) -> Void)? = nil,
    onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)? = nil,
    initialOffsetY: CGFloat = 5,
    initialRotationAngle: Double = 0.5,
    currentIndex currentIndexBinding: Binding<Int>? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.cards = cards
    self.onCardSwiped = onCardSwiped
    self.onCardDragged = onCardDragged
    self.initialOffsetY = initialOffsetY
    self.initialRotationAngle = initialRotationAngle
    self.contentBuilder = content
    self._currentIndexBinding = currentIndexBinding ?? .constant(0)
  }

  public var body: some View {
    ZStack {
      ForEach(cards.indices, id: \.self) { index in
        let relative = max(currentIndexBinding - index, currentIndex - index)

        CardView(
          index: index,
          relativeIndex: relative,
          visibleCardsCount: visibleCardsCount,
          onCardSwiped: { swipeDirection in
            onCardSwiped?(swipeDirection, index)
            if swipeDirection != .undefined {
              if currentIndex != currentIndexBinding {
                currentIndex = currentIndexBinding
              }
              currentIndex -= 1
            }
          },
          onCardDragged: { direction, index, offset in
            onCardDragged?(direction, index, offset)
          },
          content: {
            contentBuilder(cards[index])
          },
          initialOffsetY: initialOffsetY,
          initialRotationAngle: initialRotationAngle,
          zIndex: Double(cards.count - index),
          activeCardIndex: $activeCardIndex
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }

  private struct CardView<CardContent: View>: View {
    let id = UUID()
    var index: Int
    var relativeIndex: Int
    var visibleCardsCount: Int
    var onCardSwiped: ((SwipeDirection) -> Void)?
    var onCardDragged: ((SwipeDirection, Int, CGSize) -> Void)?
    var content: () -> CardContent
    var initialOffsetY: CGFloat
    var initialRotationAngle: Double
    var zIndex: Double

    @State private var offset = CGSize.zero
    @State private var overlayColor: Color = .clear
    @State private var isDismissed = false
    @State private var isRemoved = false
    @Binding var activeCardIndex: Int?

    var body: some View {
      ZStack {
        content()
          .frame(width: 320, height: 420)
          .offset(x: offset.width * 1, y: extraOffset + offset.height * 0.3)
          .scaleEffect(scale, anchor: .top)
          .rotationEffect(.degrees(Double(offset.width / 40)))
          .zIndex(zIndex)
          .opacity(relativeIndex <= visibleCardsCount ? 1 : 0)

        Rectangle()
          .foregroundColor(overlayColor)
          .opacity(isRemoved ? 0 : (activeCardIndex == index ? 1 : 0))
          .frame(width: 320, height: 420)
          .cornerRadius(10)
          .blendMode(.overlay)
          .overlay(
            Image("bookmark")
              .resizable()
              .frame(width: 60, height: 60)
              .scaleEffect(x: 1.0, y: 0.8)
              .shadow(color: .black.opacity(0.1), radius: 4)
              .opacity(bookmarkOpacity),
            alignment: .center
          )
      }
      .gesture(
        DragGesture()
          .onChanged { gesture in
            offset = gesture.translation
            activeCardIndex = index
            isDismissed = true
            withAnimation {
              onCardDragged?(swipeDirection, index, offset)
            }
          }
          .onEnded { _ in
            withAnimation {
              handleSwipe(offsetWidth: offset.width, offsetHeight: offset.height)
            }
            activeCardIndex = nil
            isDismissed = false
          }
      )
      .opacity(isRemoved ? 0 : 1)
      .blur(radius: blurRadius)
      .animation(.linear(duration: 0.4), value: activeCardIndex)
    }

    private var scale: CGFloat {
      1 - CGFloat(clamped) * 0.07
    }

    private var extraOffset: CGFloat {
      -CGFloat(clamped) * 20
    }

    private var clamped: Int {
      min(relativeIndex, visibleCardsCount)
    }

    private var dragProgress: CGFloat {
      let maxWidth: CGFloat = 160
      return min(abs(offset.width) / maxWidth, 1)
    }

    private var blurRadius: CGFloat {
      guard let active = activeCardIndex else {
        return 0
      }

      return active == index ? 0 : 3 + (3 * dragProgress)
    }

    private var bookmarkOpacity: Double {
      isDismissed ? 1 : 0
    }

    private var swipeDirection: SwipeDirection {
      switch offset.width {
      case -500...(-150):
        .left
      case 150...500:
        .right
      default:
        .undefined
      }
    }

    func handleSwipe(offsetWidth _: CGFloat, offsetHeight _: CGFloat) {
      switch swipeDirection {
      case .left:
        offset = CGSize(width: -350, height: 0)
        isRemoved = true
      case .right:
        offset = CGSize(width: 350, height: 0)
        isRemoved = true
      default:
        offset = .zero
        overlayColor = .clear
      }
      onCardSwiped?(swipeDirection)
    }
  }
}
