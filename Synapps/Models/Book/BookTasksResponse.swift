//
//  BookTasksResponse.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import Foundation
import SwiftData

@Model
final class BookTasksResponse {
  @Attribute(.unique) var id: String
  var processingStatus: String
  var totalChapters: Int
  var processedChapters: Int
  @Relationship(deleteRule: .cascade, inverse: \BookTask.parentResponse)
  var tasks: [BookTask]

  init(id: String, processingStatus: String, totalChapters: Int, processedChapters: Int, tasks: [BookTask]) {
    self.id = id
    self.processingStatus = processingStatus
    self.totalChapters = totalChapters
    self.processedChapters = processedChapters
    self.tasks = tasks
    for task in tasks {
      task.parentResponse = self
    }
  }

  var isReady: Bool {
    processingStatus == "done"
  }

  var progress: Double {
    guard totalChapters > 0 else { return 0 }
    return min(max(Double(processedChapters) / Double(totalChapters), 0), 1)
  }

  var tasksSyncSignature: String {
    "\(processingStatus)|\(tasks.count)|\(tasks.map(\.id).joined(separator: ","))"
  }
}

extension BookTasksResponse: Hashable {
  static func ==(lhs: BookTasksResponse, rhs: BookTasksResponse) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
