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
      let positions = layout()
      let totalScale = clamp(scale * pinch)
      // Suppress live drag offset while a pinch is in progress so the graph
      // doesn't fly around when both gestures are tracked simultaneously.
      let activeDrag: CGSize = pinch == 1 ? dragOffset : .zero
      let totalOffset = CGSize(
        width: offset.width + activeDrag.width,
        height: offset.height + activeDrag.height
      )

      ZStack {
        Color(.systemBackground).ignoresSafeArea()

        ZStack {
          // Edges
          Canvas { ctx, _ in
            for edge in map.edges {
              guard let a = positions[edge.from], let b = positions[edge.to] else { continue }
              var path = Path()
              path.move(to: a)
              path.addLine(to: b)
              ctx.stroke(path, with: .color(.gray.opacity(0.45)), lineWidth: 1.5)
            }
          }
          .frame(width: 4000, height: 4000)

          // Nodes
          ForEach(map.nodes) { node in
            if let p = positions[node.id] {
              nodeView(node)
                .position(p)
            }
          }
        }
        .frame(width: 4000, height: 4000)
        .scaleEffect(totalScale)
        .offset(totalOffset)
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

  // MARK: - Layout (radial, fixed canvas centred at 2000,2000)

  private func layout() -> [String: CGPoint] {
    var positions: [String: CGPoint] = [:]
    let center = CGPoint(x: 2000, y: 2000)
    guard let root = map.nodes.first(where: { $0.kind == .root }) else { return positions }
    positions[root.id] = center

    let firstRing = map.edges.filter { $0.from == root.id }.map(\.to)
    guard !firstRing.isEmpty else { return positions }

    // Children of each first-ring node (subtopic-cards or root-singleton-cards).
    let childrenByParent: [String: [String]] = Dictionary(uniqueKeysWithValues: firstRing.map { id in
      (id, map.edges.filter { $0.from == id }.map(\.to))
    })

    let cardArc = cardWidth + cardGap                 // 300pt
    let spreadRad = subFanSpread * .pi / 180
    let nodeKind: (String) -> MindMapNode.Kind? = { id in map.nodes.first { $0.id == id }?.kind }

    // Per-subtopic r2 so that adjacent cards in its fan don't overlap.
    func r2For(parentId: String) -> CGFloat {
      let kids = childrenByParent[parentId] ?? []
      guard kids.count > 1 else { return minR2 }
      let needed = cardArc * CGFloat(kids.count - 1) / CGFloat(spreadRad)
      return max(minR2, needed)
    }

    // Bounding fan-width (perpendicular to radius) for a subtopic + its children.
    func fanWidth(parentId: String) -> CGFloat {
      let kids = childrenByParent[parentId] ?? []
      let kind = nodeKind(parentId)
      if kind == .card { return cardWidth + cardGap }   // root-singleton card slot
      if kids.isEmpty { return cardWidth + cardGap }
      let r2 = r2For(parentId: parentId)
      let halfChord = r2 * CGFloat(Foundation.sin(spreadRad / 2))
      return 2 * halfChord + cardWidth + cardGap
    }

    let widths = firstRing.map { fanWidth(parentId: $0) }
    let maxWidth = widths.max() ?? cardArc

    // r1 large enough so each subtopic gets its angular slice ≥ its fanWidth.
    let n = firstRing.count
    let neededR1 = maxWidth * CGFloat(n) / (2 * .pi)
    let r1 = max(minR1, neededR1)

    for (i, nodeId) in firstRing.enumerated() {
      let angle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
      positions[nodeId] = CGPoint(
        x: center.x + CGFloat(Foundation.cos(angle)) * r1,
        y: center.y + CGFloat(Foundation.sin(angle)) * r1
      )
    }

    for (i, parentId) in firstRing.enumerated() {
      guard let parent = positions[parentId] else { continue }
      let kids = childrenByParent[parentId] ?? []
      guard !kids.isEmpty else { continue }
      let baseAngle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
      let r2 = r2For(parentId: parentId)
      // Outward direction = baseAngle (away from root).
      for (j, childId) in kids.enumerated() {
        let t = kids.count == 1 ? 0.5 : Double(j) / Double(kids.count - 1)
        let angle = baseAngle - spreadRad / 2 + t * spreadRad
        positions[childId] = CGPoint(
          x: parent.x + CGFloat(Foundation.cos(angle)) * r2,
          y: parent.y + CGFloat(Foundation.sin(angle)) * r2
        )
      }
    }
    return positions
  }
}
