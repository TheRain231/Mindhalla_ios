//
//  BookTasksResponse.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import Foundation

struct BookTasksResponse: Hashable {
  let id: String
  let processingStatus: String
  let totalChapters: Int
  let processedChapters: Int
  let tasks: [BookTask]

  var isReady: Bool {
    processingStatus == "done"
  }

  var progress: Double {
    guard totalChapters > 0 else { return 0 }
    return min(max(Double(processedChapters) / Double(totalChapters), 0), 1)
  }
}

struct BookTask: Hashable, Identifiable {
  let id: String
  let title: String
  let options: [BookTaskOption]
  let correctOptionIds: [String]
  let hint: String
  let explanation: String
}

struct BookTaskOption: Hashable, Identifiable {
  let id: String
  let text: String
}
