//
//  Book.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

struct Book {
  let title: String
  let author: String
  let coverImageUrl: URL?
  let savedIdeasCount: Int

  let ideasCount: Int
  let ideasRead: Int

  var percentageRead: Double {
    guard ideasCount > 0 else { return 0 }
    return (Double(ideasRead) / Double(ideasCount)) * 100
  }

  var timeToRead: TimeInterval {
    let remainingideas = max(ideasCount - ideasRead, 0)
    return TimeInterval(remainingideas) * 60
  }
}
