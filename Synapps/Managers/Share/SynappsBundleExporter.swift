import Foundation

enum SynappsBundleExporter {
  enum ExportError: Error {
    case encodingFailed(Error)
    case writeFailed(Error)
  }

  static func export(card: Card) throws -> URL {
    let bundle = SynappsBundle(
      version: SynappsBundleVersion.current,
      type: .card,
      exportedAt: Date(),
      payload: .card(CardDTO(card: card))
    )
    let slug = slugify(card.content.prefix(40).description, fallback: "card")
    return try write(bundle: bundle, slug: slug)
  }

  static func export(collection: QuoteCollection, cards: [Card]) throws -> URL {
    let dto = CollectionDTO(id: collection.id, title: collection.title, cardIds: collection.cardIds)
    let bundle = SynappsBundle(
      version: SynappsBundleVersion.current,
      type: .collection,
      exportedAt: Date(),
      payload: .collection(CollectionPayload(collection: dto, cards: cards.map(CardDTO.init(card:))))
    )
    let slug = slugify(collection.title, fallback: "collection")
    return try write(bundle: bundle, slug: slug)
  }

  static func export(mindMap: MindMap, sourceCards: [Card]) throws -> URL {
    let bundle = SynappsBundle(
      version: SynappsBundleVersion.current,
      type: .mindmap,
      exportedAt: Date(),
      payload: .mindmap(MindMapPayload(
        title: mindMap.title,
        bookId: mindMap.bookId,
        cards: sourceCards.map(CardDTO.init(card:))
      ))
    )
    let slug = slugify(mindMap.title, fallback: "mindmap")
    return try write(bundle: bundle, slug: slug)
  }

  // MARK: - Private

  private static func write(bundle: SynappsBundle, slug: String) throws -> URL {
    let data: Data
    do {
      data = try SynappsBundleCoder.encoder().encode(bundle)
    } catch {
      throw ExportError.encodingFailed(error)
    }

    // Уникальная поддиректория в temp, чтобы избежать конфликтов с одним и тем же slug.
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let url = dir.appendingPathComponent("\(slug)-\(dateStamp()).synapps")
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      try data.write(to: url, options: .atomic)
    } catch {
      throw ExportError.writeFailed(error)
    }
    return url
  }

  private static func slugify(_ raw: String, fallback: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    var slug = ""
    var lastWasDash = false
    for scalar in raw.unicodeScalars {
      if allowed.contains(scalar) {
        slug.unicodeScalars.append(scalar)
        lastWasDash = false
      } else if !lastWasDash {
        slug.append("-")
        lastWasDash = true
      }
    }
    slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return slug.isEmpty ? fallback : String(slug.prefix(50))
  }

  private static func dateStamp() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }
}
