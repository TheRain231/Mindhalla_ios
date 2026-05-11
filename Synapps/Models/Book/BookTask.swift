//
//  BookTask.swift
//  Synapps
//

import Foundation
import SwiftData

@Model
final class BookTask {
  var id: String
  var title: String
  var correctOptionIds: [String]
  var hint: String
  var explanation: String
  @Relationship(deleteRule: .cascade, inverse: \BookTaskOption.parentTask)
  var options: [BookTaskOption]
  var parentResponse: BookTasksResponse?

  init(id: String, title: String, options: [BookTaskOption], correctOptionIds: [String], hint: String, explanation: String) {
    self.id = id
    self.title = title
    self.correctOptionIds = correctOptionIds
    self.hint = hint
    self.explanation = explanation
    self.options = options
    for option in self.options {
      option.parentTask = self
    }
  }
}

extension BookTask: Identifiable {}
