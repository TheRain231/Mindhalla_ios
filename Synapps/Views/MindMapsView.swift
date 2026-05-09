import SwiftData
import SwiftUI

struct MindMapsView: View {
  @Environment(\.viewModelFactory) var factory
  @ObservedObject var viewModel: ViewModel
  @Query var cards: [Card]
  @Query var allBooks: [BookMetaResponse]

  var body: some View {
    NavigationStack {
      content
        .navigationTitle(Text("mind_maps"))
        .task(id: cards.count) {
          await viewModel.rebuild(cards: cards, books: allBooks)
        }
        .navigationDestination(item: $viewModel.openedMap) { map in
          MindMapDetailView(map: map)
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.isBuilding && viewModel.sections.isEmpty {
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if viewModel.sections.isEmpty {
      VStack(spacing: 12) {
        Image(systemName: "brain")
          .font(.system(size: 48))
          .foregroundStyle(.secondary)
        Text("mind_maps.empty")
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 32)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let subs = map.nodes.filter { $0.kind == .subtopic }.prefix(5)
        let r: CGFloat = min(size.width, size.height) / 2 - 14
        for (i, _) in subs.enumerated() {
          let angle = 2 * Double.pi * Double(i) / Double(max(subs.count, 1))
          let p = CGPoint(x: center.x + CGFloat(Foundation.cos(angle)) * r, y: center.y + CGFloat(Foundation.sin(angle)) * r)
          var line = Path()
          line.move(to: center)
          line.addLine(to: p)
          ctx.stroke(line, with: .color(.gray.opacity(0.4)), lineWidth: 1)
          ctx.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(MindMapPalette.secondary))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(MindMapPalette.primary))
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

    func rebuild(cards: [Card], books: [BookMetaResponse]) async {
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
        let titles = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0.title) })
        let grouped = Dictionary(grouping: maps) { $0.bookId ?? "" }
        let sections = grouped.map { key, value in
          Section(
            id: key.isEmpty ? "general" : key,
            title: key.isEmpty ? "General" : (titles[key] ?? "General"),
            maps: value
          )
        }.sorted { $0.maps.count > $1.maps.count }
        self.sections = sections
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
