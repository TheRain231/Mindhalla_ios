//
//  BookExtensions.swift
//  Synapps
//
//  Created by Andrey Stepanov on 29.09.2025.
//

import Foundation

#if DEBUG
extension Book {
  static func mock() -> Book {
    let coverUrl = URL(string: "https://main-cdn.sbermegamarket.ru/hlr-system/131/227/639/991/113/50/600002347616b0.jpeg")!
    return Book(
      title: "Mock Book",
      author: "Mock Author",
      coverImageUrl: coverUrl,
      savedIdeasCount: 0,
      ideasCount: 100,
      ideasRead: 0
    )
  }

  static func mockWithoutURL() -> Book {
    Book(
      title: "Mock Book",
      author: "Mock Author",
      coverImageUrl: nil,
      savedIdeasCount: 0,
      ideasCount: 100,
      ideasRead: 0
    )
  }

  static func mockWithURLError() -> Book {
    let coverUrl: URL? = URL(string: "https:tutcartinkinet.ry/cartinka.jpeg")!
    return Book(
      title: "Mock Book",
      author: "Mock Author",
      coverImageUrl: coverUrl,
      savedIdeasCount: 0,
      ideasCount: 100,
      ideasRead: 0
    )
  }
}
#endif
