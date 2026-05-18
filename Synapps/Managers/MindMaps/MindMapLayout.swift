import CoreGraphics
import Foundation

@MainActor
enum MindMapLayout {
  static func radialPositions(
    for map: MindMap,
    cardWidth: CGFloat = 170,
    cardGap: CGFloat = 24,
    subFanSpread: Double = 110,
    minR1: CGFloat = 180,
    minR2: CGFloat = 280,
    canvasCenter: CGPoint = CGPoint(x: 2000, y: 2000)
  ) -> [String: CGPoint] {
    var positions: [String: CGPoint] = [:]
    guard let root = map.nodes.first(where: { $0.kind == .root }) else { return positions }
    positions[root.id] = canvasCenter

    let firstRing = map.edges.filter { $0.from == root.id }.map(\.to)
    guard !firstRing.isEmpty else { return positions }

    let childrenByParent: [String: [String]] = Dictionary(uniqueKeysWithValues: firstRing.map { id in
      (id, map.edges.filter { $0.from == id }.map(\.to))
    })

    let cardArc = cardWidth + cardGap
    let spreadRad = subFanSpread * .pi / 180
    let nodeKind: (String) -> MindMapNode.Kind? = { id in map.nodes.first { $0.id == id }?.kind }

    func r2For(parentId: String) -> CGFloat {
      let kids = childrenByParent[parentId] ?? []
      guard kids.count > 1 else { return minR2 }
      // Exact chord formula: adjacent kids on a fan of total angle `spreadRad`
      // sit `2*r2*sin(step/2)` apart; require that chord >= cardArc.
      let step = spreadRad / Double(kids.count - 1)
      let denom = max(2 * Foundation.sin(step / 2), 1e-3)
      let needed = CGFloat(Double(cardArc) / denom)
      return max(minR2, needed * 1.25)
    }

    func fanWidth(parentId: String) -> CGFloat {
      let kind = nodeKind(parentId)
      if kind == .card { return cardWidth + cardGap }
      // r1 разводит только сами капсулы подтем; веера соседних подтем могут
      // перекрываться по углу — это принятый трейдоф ради коротких r1-рёбер.
      let subtopicWidth: CGFloat = 180
      let gap: CGFloat = 24
      return subtopicWidth + gap
    }

    let widths = firstRing.map { fanWidth(parentId: $0) }
    let maxWidth = widths.max() ?? cardArc

    let n = firstRing.count
    // Exact chord on the root ring: adjacent first-ring nodes are
    // `2*r1*sin(π/n)` apart; require that chord >= maxWidth (with a safety margin).
    let denomR1 = max(2 * Foundation.sin(.pi / Double(n)), 1e-3)
    let neededR1 = CGFloat(Double(maxWidth) / denomR1) * 1.25
    // If any first-ring child is a card (singleton attached directly to root),
    // push the ring out so the card body doesn't sit on top of the root capsule
    // and a visible edge segment remains between them.
    let hasDirectCardChild = firstRing.contains { nodeKind($0) == .card }
    let cardMinR1: CGFloat = hasDirectCardChild ? cardWidth + 160 : minR1
    // Когда первое кольцо содержит подтемы — у каждой свой веер карточек уходит
    // наружу. Подтянем r1 так чтобы между корневой капсулой и капсулой подтемы
    // оставался видимый сегмент ребра (иначе они визуально слипаются).
    let hasSubtopicChild = firstRing.contains { nodeKind($0) == .subtopic }
    let subtopicMinR1: CGFloat = hasSubtopicChild ? 400 : minR1
    // Анти-коллизия: крайние карточки соседних подтем разнесены минимум на cardArc.
    // Подтемы A и B расположены под углом ±h от оси (h = π/n) на радиусе r1.
    // Крайняя карточка A имеет y = -r1·sin(h) + r2·sin(spread/2 - h), для B — зеркально.
    // Расстояние между ними = 2·|r1·sin(h) - r2·sin(spread/2 - h)|, требуем ≥ cardArc.
    let h = Double.pi / Double(n)
    let sinH = Foundation.sin(h)
    let sinDiff = Foundation.sin(spreadRad / 2 - h)
    var collisionR1: CGFloat = 0
    if sinDiff > 0, sinH > 1e-3 {
      for i in 0..<n {
        let a = firstRing[i]
        let b = firstRing[(i + 1) % n]
        guard nodeKind(a) == .subtopic, nodeKind(b) == .subtopic else { continue }
        let r2 = max(r2For(parentId: a), r2For(parentId: b))
        let required = (r2 * CGFloat(sinDiff) + cardArc / 2) / CGFloat(sinH)
        collisionR1 = max(collisionR1, required)
      }
    }
    let r1 = max(max(max(max(minR1, cardMinR1), subtopicMinR1), neededR1), collisionR1)

    for (i, nodeId) in firstRing.enumerated() {
      let angle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
      positions[nodeId] = CGPoint(
        x: canvasCenter.x + CGFloat(Foundation.cos(angle)) * r1,
        y: canvasCenter.y + CGFloat(Foundation.sin(angle)) * r1
      )
    }

    for (i, parentId) in firstRing.enumerated() {
      guard let parent = positions[parentId] else { continue }
      let kids = childrenByParent[parentId] ?? []
      guard !kids.isEmpty else { continue }
      let baseAngle = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
      let r2 = r2For(parentId: parentId)
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
