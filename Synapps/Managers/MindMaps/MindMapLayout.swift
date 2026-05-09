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
      let needed = cardArc * CGFloat(kids.count - 1) / CGFloat(spreadRad)
      return max(minR2, needed)
    }

    func fanWidth(parentId: String) -> CGFloat {
      let kids = childrenByParent[parentId] ?? []
      let kind = nodeKind(parentId)
      if kind == .card { return cardWidth + cardGap }
      if kids.isEmpty { return cardWidth + cardGap }
      let r2 = r2For(parentId: parentId)
      let halfChord = r2 * CGFloat(Foundation.sin(spreadRad / 2))
      return 2 * halfChord + cardWidth + cardGap
    }

    let widths = firstRing.map { fanWidth(parentId: $0) }
    let maxWidth = widths.max() ?? cardArc

    let n = firstRing.count
    let neededR1 = maxWidth * CGFloat(n) / (2 * .pi)
    let r1 = max(minR1, neededR1)

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
