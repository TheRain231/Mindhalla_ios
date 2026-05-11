//
//  BookTasksPersistence.swift
//  Synapps
//

import Foundation
import SwiftData

extension BookTasksResponse {
  @MainActor
  static func persist(_ snapshot: BookTasksResponse, modelContext: ModelContext) throws {
    let snapshotId = snapshot.id
    var descriptor = FetchDescriptor<BookTasksResponse>(predicate: #Predicate { $0.id == snapshotId })
    descriptor.fetchLimit = 1
    if let existing = try modelContext.fetch(descriptor).first {
      if existing === snapshot {
        try modelContext.save()
        return
      }
      modelContext.delete(existing)
    }
    modelContext.insert(snapshot)
    try modelContext.save()
  }
}
