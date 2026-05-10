//
//  BookTaskOption.swift
//  Synapps
//

import Foundation
import SwiftData

@Model
final class BookTaskOption {
  var id: String
  var text: String
  var parentTask: BookTask?

  init(id: String, text: String) {
    self.id = id
    self.text = text
  }
}

extension BookTaskOption: Identifiable {}
