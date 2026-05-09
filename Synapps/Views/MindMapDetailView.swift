import SwiftUI

struct MindMapDetailView: View {
  let map: MindMap

  @Environment(\.viewModelFactory) private var factory
  @State private var scale: CGFloat = 1
  @GestureState private var pinch: CGFloat = 1
  @State private var offset: CGSize = .zero
  @GestureState private var dragOffset: CGSize = .zero
  @State private var openCardId: CardLink?

  private struct CardLink: Identifiable, Hashable { let id: String }

  // Card leaves are full CardCardView at this width; subtopics/root sized to text.
  private let cardWidth: CGFloat = 170
  private let cardScale: CGFloat = 0.7      // visually shrink CardCardView to fit graph density
  private let cardGap: CGFloat = 24         // min space between adjacent cards
  private let subFanSpread: Double = 110    // angular spread (deg) of cards around a subtopic
  private let minR1: CGFloat = 180
  private let minR2: CGFloat = 280

  var body: some View {
    GeometryReader { geo in
      let positions = MindMapLayout.radialPositions(
        for: map,
        cardWidth: cardWidth, cardGap: cardGap,
        subFanSpread: subFanSpread,
        minR1: minR1, minR2: minR2
      )
      let totalScale = clamp(scale * pinch)
      // Suppress live drag offset while a pinch is in progress so the graph
      // doesn't fly around when both gestures are tracked simultaneously.
      let activeDrag: CGSize = pinch == 1 ? dragOffset : .zero
      let totalOffset = CGSize(
        width: offset.width + activeDrag.width,
        height: offset.height + activeDrag.height
      )
      let layoutCenter = CGPoint(x: 2000, y: 2000)
      let screenCenter = CGPoint(
        x: geo.size.width / 2 + totalOffset.width,
        y: geo.size.height / 2 + totalOffset.height
      )
      // Map a layout-space point to screen coordinates with current zoom & pan.
      let project: (CGPoint) -> CGPoint = { p in
        CGPoint(
          x: screenCenter.x + (p.x - layoutCenter.x) * totalScale,
          y: screenCenter.y + (p.y - layoutCenter.y) * totalScale
        )
      }

      ZStack {
        Color(.systemBackground).ignoresSafeArea()

        // Edges drawn directly in screen coordinates — no scaleEffect on the canvas
        // so vertices and edges stay aligned at any zoom level.
        Canvas { ctx, _ in
          for edge in map.edges {
            guard let a = positions[edge.from], let b = positions[edge.to] else { continue }
            var path = Path()
            path.move(to: project(a))
            path.addLine(to: project(b))
            ctx.stroke(path, with: .color(.gray.opacity(0.45)), lineWidth: 1.5)
          }
        }
        .allowsHitTesting(false)

        // Nodes positioned in screen coordinates, individually scaled.
        ForEach(map.nodes) { node in
          if let p = positions[node.id] {
            nodeView(node)
              .scaleEffect(totalScale, anchor: .center)
              .position(project(p))
          }
        }
      }
      .contentShape(Rectangle())
      .gesture(
        SimultaneousGesture(
          MagnificationGesture()
            .updating($pinch) { value, state, _ in state = value }
            .onEnded { value in scale = clamp(scale * value) },
          DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in state = value.translation }
            .onEnded { value in
              offset = CGSize(
                width: offset.width + value.translation.width,
                height: offset.height + value.translation.height
              )
            }
        )
      )
      .onTapGesture(count: 2) {
        withAnimation { scale = 1; offset = .zero }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .overlay(alignment: .bottomTrailing) {
        zoomControls
          .padding(16)
      }
    }
    .navigationTitle(map.title)
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $openCardId) { link in
      CardsView(viewModel: factory.createCardsViewModel(cardID: link.id, prefetchedBook: nil))
    }
  }

  // MARK: - Node views (titles inside shapes)

  @ViewBuilder
  private func nodeView(_ node: MindMapNode) -> some View {
    switch node.kind {
    case .root:
      Text(node.title)
        .font(.title3.bold())
        .foregroundStyle(Color.white)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: 220)
        .background(Capsule().fill(MindMapPalette.primary))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    case .subtopic:
      Text(node.title)
        .font(.headline)
        .foregroundStyle(Color.white)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 180)
        .background(Capsule().fill(MindMapPalette.secondary))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    case .card:
      if let card = node.card {
        CardCardView(card: card)
          .frame(width: cardWidth / cardScale)
          .fixedSize(horizontal: true, vertical: true)
          .scaleEffect(cardScale, anchor: .center)
          .onTapGesture { openCardId = CardLink(id: card.id) }
      }
    }
  }

  private func clamp(_ v: CGFloat) -> CGFloat { min(max(v, 0.2), 4.0) }

  private var zoomControls: some View {
    VStack(spacing: 8) {
      Button { withAnimation { scale = clamp(scale * 1.3) } } label: {
        Image(systemName: "plus.magnifyingglass").font(.title3)
      }
      Button { withAnimation { scale = clamp(scale / 1.3) } } label: {
        Image(systemName: "minus.magnifyingglass").font(.title3)
      }
      Button { withAnimation { scale = 1; offset = .zero } } label: {
        Image(systemName: "arrow.up.left.and.down.right.magnifyingglass").font(.title3)
      }
    }
    .padding(10)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .foregroundStyle(MindMapPalette.primary)
  }

}
