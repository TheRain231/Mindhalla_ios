import SwiftData
import SwiftUI

struct MindMapsView: View {
  @Environment(\.viewModelFactory) var factory
  @ObservedObject var viewModel: ViewModel
  @Query(filter: #Predicate<Card> { $0.savedAt != nil }) var cards: [Card]

  var body: some View {
    NavigationStack {
      content
        .navigationTitle(Text("mind_maps"))
        .task(id: cards.count) {
          await viewModel.rebuild(cards: cards)
        }
        .navigationDestination(item: $viewModel.openedMap) { map in
          MindMapDetailView(map: map)
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isBuilding, viewModel.sections.isEmpty {
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if viewModel.sections.isEmpty {
      EmptyStateView(
        icon: "brain",
        title: "mind_maps.empty.title",
        message: "mind_maps.empty"
      )
    } else {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.sections) { section in
            VStack(alignment: .leading, spacing: 12) {
              Text(section.title).font(.title3.bold()).padding(.horizontal)
              ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                  ForEach(section.maps) { map in
                    MindMapPreviewCard(map: map)
                      .onTapGesture { viewModel.open(map) }
                  }
                }
                .padding(.horizontal)
              }
            }
          }
        }
        .padding(.vertical)
      }
    }
  }
}

private struct MindMapPreviewCard: View {
  let map: MindMap

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Canvas { ctx, size in
        let positions = MindMapLayout.radialPositions(for: map)
        let pts = Array(positions.values)
        guard !pts.isEmpty else { return }
        let minX = pts.map(\.x).min()!
        let maxX = pts.map(\.x).max()!
        let minY = pts.map(\.y).min()!
        let maxY = pts.map(\.y).max()!
        let bbox = CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))
        let scale = min(size.width / bbox.width, size.height / bbox.height) * 0.85
        let project: (CGPoint) -> CGPoint = { p in
          CGPoint(
            x: size.width / 2 + (p.x - bbox.midX) * scale,
            y: size.height / 2 + (p.y - bbox.midY) * scale
          )
        }
        for edge in map.edges {
          guard let a = positions[edge.from], let b = positions[edge.to] else { continue }
          var path = Path()
          path.move(to: project(a))
          path.addLine(to: project(b))
          ctx.stroke(path, with: .color(.gray.opacity(0.45)), lineWidth: 0.8)
        }
        for node in map.nodes {
          guard let p = positions[node.id] else { continue }
          let r: CGFloat
          let color: Color
          switch node.kind {
          case .root: r = 8; color = MindMapPalette.primary
          case .subtopic: r = 5; color = MindMapPalette.secondary
          case .card: r = 2.5; color = .gray.opacity(0.7)
          }
          let pp = project(p)
          ctx.fill(
            Path(ellipseIn: CGRect(x: pp.x - r, y: pp.y - r, width: 2 * r, height: 2 * r)),
            with: .color(color)
          )
        }
      }
      .frame(width: 160, height: 130)
      .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))

      Text(map.title)
        .font(.subheadline.bold())
        .lineLimit(1)
      Text("\(map.cardCount) cards")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(width: 160)
  }
}

extension MindMapsView {
  struct Section: Identifiable {
    let id: String
    let title: String
    let maps: [MindMap]
  }

  @MainActor
  final class ViewModel: ObservableObject {
    @Published var sections: [Section] = []
    @Published var openedMap: MindMap?
    @Published private(set) var isBuilding = false

    private let builder: MindMapBuilder
    private var lastSignature: Int?

    init(builder: MindMapBuilder) {
      self.builder = builder
    }

    func rebuild(cards: [Card]) async {
      let signature = cards.reduce(into: Hasher()) { hasher, card in
        hasher.combine(card.id)
        for tag in card.tags where tag.type == AutoTaggingService.autoTagType {
          hasher.combine(tag.id)
        }
      }.finalize()
      if signature == lastSignature { return }
      lastSignature = signature

      isBuilding = true
      defer { isBuilding = false }
      do {
        let maps = try await builder.build(from: cards)
        let groups = try await builder.groupByMetaTopic(maps)
        self.sections = groups.map { Section(id: $0.id, title: $0.title, maps: $0.maps) }
      } catch {
        print("[MindMaps] build failed: \(error)")
        self.sections = []
      }
    }

    func open(_ map: MindMap) {
      openedMap = map
    }
  }
}

#Preview {
  let factory = MockViewModelFactory()
  return MindMapsView(viewModel: factory.createMindMapsViewModel())
    .modelContainer(factory.modelContainer)
    .environment(\.viewModelFactory, factory)
}
