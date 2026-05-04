//
//  BookTasksResponseExtensions.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import Foundation

extension BookTasksResponse {
  init(dto: BookTasksResponseDTO) {
    self.init(
      id: dto.id,
      processingStatus: dto.processingStatus,
      totalChapters: dto.totalChapters,
      processedChapters: dto.processedChapters,
      tasks: dto.tasks.map {
        BookTask(
          id: $0.id,
          title: $0.title,
          options: $0.options.map { BookTaskOption(id: $0.id, text: $0.text) },
          correctOptionIds: $0.correctOptionIds,
          hint: $0.hint,
          explanation: $0.explanation
        )
      }
    )
  }
}
