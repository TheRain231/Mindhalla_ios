import SwiftUI

struct MindMapDetailView: View {
  let map: MindMap

  @Environment(\.viewModelFactory) private var factory
  @State private var scale: CGFloat = 1
  @GestureState private var pinch: CGFloat = 1
  @State private var offset: CGSize = .zero
  @GestureState private var dragOffset: CGSize = .zero
  @State private var openCardId: CardLink?

  private struct CardLink: Identifiable, Hashable {
    let id: String
  }

  private let rootRadius: CGFloat = 28
  private let subRadius: CGFloat = 20
  private let cardRadius: CGFloat = 12

  var body: some View {
    GeometryReader { geo in
      let positions = layout(in: geo.size)
      let totalScale = scale * pinch
      let totalOffset = CGSize(width: offset.width + dragOffset.width, height: offset.height + dragOffset.height)
      let center = CGPoint(x: geo.size.width / 2 + totalOffset.width, y: geo.size.height / 2 + totalOffset.height)

      ZStack {
        Color(.systemBackground).ignoresSafeArea()

        Canvas { ctx, _ in
          for edge in map.edges {
            guard let a = positions[edge.from], let b = positions[edge.to] else { continue }
            var path = Path()
            path.move(to: project(a, center: center, scale: totalScale))
            path.addLine(to: project(b, center: center, scale: totalScale))
            ctx.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 1)
          }
          for node in map.nodes {
            guard let p = positions[node.id] else { continue }
            let pt = project(p, center: center, scale: totalScale)
            let r = radius(for: node.kind) * totalScale
            let rect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(color(for: node.kind)))
          }
        }
        .ignoresSafeArea()

        ForEach(map.nodes) { node in
          if let p = positions[node.id] {
            let pt = project(p, center: center, scale: totalScale)
            NodeLabel(node: node, scale: totalScale)
              .position(x: pt.x, y: pt.y + radius(for: node.kind) * totalScale + 12 * max(totalScale, 0.6))
              .onTapGesture {
                if node.kind == .card, let cardId = node.cardId {
                  openCardId = CardLink(id: cardId)
                }
              }
              .allowsHitTesting(node.kind == .card)
          }
        }
      }
      .contentShape(Rectangle())
      .gesture(
        MagnificationGesture()
          .updating($pinch) { value, state, _ in state = value }
          .onEnded { value in scale = clamp(scale * value) }
      )
      .simultaneousGesture(
        DragGesture()
          .updating($dragOffset) { value, state, _ in state = value.translation }
          .onEnded { value in
            offset = CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height)
          }
      )
      .onTapGesture(count: 2) {
        withAnimation { scale = 1; offset = .zero }
      }
    }
    .navigationTitle(map.title)
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(item: $openCardId) { link in
      CardsView(viewModel: factory.createCardsViewModel(cardID: link.id, prefetchedBook: nil))
    }
  }

  private func clamp(_ v: CGFloat) -> CGFloat {
    min(max(v, 0.4), 4.0)
  }

  private func radius(for kind: MindMapNode.Kind) -> CGFloat {
    switch kind {
    case .root: rootRadius
    case .subtopic: subRadius
    case .card: cardRadius
    }
  }

  private func color(for kind: MindMapNode.Kind) -> Color {
    switch kind {
    case .root: .accentColor
    case .subtopic: .accentColor.opacity(0.7)
    case .card: Color(.tertiarySystemFill)
    }
  }

  private func project(_ p: CGPoint, center: CGPoint, scale: CGFloat) -> CGPoint {
    CGPoint(x: center.x + p.x * scale, y: center.y + p.y * scale)
  }

  private func layout(in size: CGSize) -> [String: CGPoint] {
    var positions: [String: CGPoint] = [:]
    guard let root = map.nodes.first(where: { $0.kind == .root }) else { return positions }
    positions[root.id] = .zero

    let subEdges = map.edges.filter { $0.from == root.id }
    let firstRing = subEdges.map(\.to)
    let r1: CGFloat = 170
    let r2: CGFloat = 90

    for (i, nodeId) in firstRing.enumerated() {
      let angle = 2 * Double.pi * Double(i) / Double(max(firstRing.count, 1)) - Double.pi / 2
      positions[nodeId] = CGPoint(x: CGFloat(Foundation.cos(angle)) * r1, y: CGFloat(Foundation.sin(angle)) * r1)
    }

    for (i, parentId) in firstRing.enumerated() {
      guard let parent = positions[parentId] else { continue }
      let children = map.edges.filter { $0.from == parentId }.map(\.to)
      guard !children.isEmpty else { continue }
      let baseAngle = 2 * Double.pi * Double(i) / Double(max(firstRing.count, 1)) - Double.pi / 2
      let spread = Double.pi / 2
      for (j, childId) in children.enumerated() {
        let t = children.count == 1 ? 0.5 : Double(j) / Double(children.count - 1)
        let angle = baseAngle - spread / 2 + t * spread
        positions[childId] = CGPoint(x: parent.x + CGFloat(Foundation.cos(angle)) * r2, y: parent.y + CGFloat(Foundation.sin(angle)) * r2)
      }
    }
    return positions
  }
}

private struct NodeLabel: View {
  let node: MindMapNode
  let scale: CGFloat

  var body: some View {
    Text(node.title)
      .font(font)
      .lineLimit(2)
      .multilineTextAlignment(.center)
      .frame(maxWidth: maxWidth)
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
      .background(Color(.systemBackground).opacity(0.8))
      .cornerRadius(4)
  }

  private var font: Font {
    switch node.kind {
    case .root: .headline
    case .subtopic: .subheadline
    case .card: .caption
    }
  }

  private var maxWidth: CGFloat {
    switch node.kind {
    case .root: 200
    case .subtopic: 140
    case .card: 110
    }
  }
}

