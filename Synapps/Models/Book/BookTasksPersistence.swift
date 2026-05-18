//
//  BookTasksPersistence.swift
//  Synapps
//

import Foundation
import SwiftData

extension BookTasksResponse {
  @MainActor
  static func persist(_ snapshot: BookTasksResponse, modelContext: ModelContext) throws -> BookTasksResponse {
    let snapshotId = snapshot.id
    var descriptor = FetchDescriptor<BookTasksResponse>(predicate: #Predicate { $0.id == snapshotId })
    descriptor.fetchLimit = 1
    if let existing = try modelContext.fetch(descriptor).first {
      if existing !== snapshot {
        guard existing.persistenceSignature != snapshot.persistenceSignature else {
          return existing
        }
        existing.processingStatus = snapshot.processingStatus
        existing.totalChapters = snapshot.totalChapters
        existing.processedChapters = snapshot.processedChapters
        existing.tasks = snapshot.tasks
        for task in existing.tasks {
          task.parentResponse = existing
        }
      }
      try modelContext.save()
      return existing
    }

    modelContext.insert(snapshot)
    try modelContext.save()
    return snapshot
  }

  private var persistenceSignature: String {
    [
      processingStatus,
      String(totalChapters),
      String(processedChapters),
      tasks.map(\.persistenceSignature).joined(separator: "#"),
    ].joined(separator: "|")
  }
}

extension BookTask {
  fileprivate var persistenceSignature: String {
    [
      id,
      title,
      correctOptionIds.joined(separator: ","),
      hint,
      explanation,
      options.map(\.persistenceSignature).joined(separator: "#"),
    ].joined(separator: "|")
  }
}

extension BookTaskOption {
  fileprivate var persistenceSignature: String {
    [id, text].joined(separator: "|")
  }
}
