//
//  BookByIdPersistence.swift
//  Synapps
//

import Foundation
import SwiftData

extension BookByIdResponse {
  @MainActor
  static func persist(_ snapshot: BookByIdResponse, modelContext: ModelContext) throws {
    let snapshotId = snapshot.id
    var descriptor = FetchDescriptor<BookByIdResponse>(predicate: #Predicate { $0.id == snapshotId })
    descriptor.fetchLimit = 1
    if let existing = try modelContext.fetch(descriptor).first {
      if existing === snapshot {
        try modelContext.save()
        return
      }
      mergeScalarFields(from: snapshot, into: existing)
      let newIds = Set(snapshot.cards.map(\.id))
      let resolved = snapshot.cards.map { Card.mergeOrInsertDeck($0, modelContext: modelContext) }
      for card in existing.cards where !newIds.contains(card.id) && card.savedAt == nil {
        modelContext.delete(card)
      }
      existing.cards = resolved
      try modelContext.save()
      return
    }
    let resolvedCards = snapshot.cards.map { Card.mergeOrInsertDeck($0, modelContext: modelContext) }
    snapshot.cards = resolvedCards
    modelContext.insert(snapshot)
    try modelContext.save()
  }

  private static func mergeScalarFields(from incoming: BookByIdResponse, into existing: BookByIdResponse) {
    existing.title = incoming.title
    existing.editionNumber = incoming.editionNumber
    existing.year = incoming.year
    existing.publisher = incoming.publisher
    existing.language = incoming.language
    existing.pages = incoming.pages
    existing.authorsBooks = incoming.authorsBooks
    existing.genresBooks = incoming.genresBooks
    existing.processingStatus = incoming.processingStatus
    existing.coverImageUrl = incoming.coverImageUrl
    existing.filename = incoming.filename
    existing.totalChapters = incoming.totalChapters
    existing.processedChapters = incoming.processedChapters
  }

  var cardIdsSignature: String {
    "\(processingStatus)|\(cards.count)|\(cards.map(\.id).joined(separator: ","))"
  }
}

extension BookByIdResponse: Hashable {
  static func ==(lhs: BookByIdResponse, rhs: BookByIdResponse) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Card {
  @MainActor
  static func mergeOrInsertDeck(_ incoming: Card, modelContext: ModelContext) -> Card {
    let incomingId = incoming.id
    var descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == incomingId })
    descriptor.fetchLimit = 1
    if let existing = try? modelContext.fetch(descriptor).first {
      existing.type = incoming.type
      existing.content = incoming.content
      existing.references = incoming.references
      existing.tags = incoming.tags
      return existing
    }
    modelContext.insert(incoming)
    return incoming
  }
}
