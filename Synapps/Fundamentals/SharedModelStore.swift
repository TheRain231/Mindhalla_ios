import Foundation
import SwiftData

enum SharedModelStore {
  static let schema = Schema([
    BookByIdResponse.self,
    BookMetaResponse.self,
    QuoteCollection.self,
    Card.self,
    BookTasksResponse.self,
    BookTask.self,
    BookTaskOption.self,
  ])

  static func makeConfiguration() -> ModelConfiguration {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier) else {
      // Fallback to default location (e.g. in unit tests or simulator without App Group)
      return ModelConfiguration(
        for: BookByIdResponse.self,
        BookMetaResponse.self,
        QuoteCollection.self,
        Card.self,
        BookTasksResponse.self,
        BookTask.self,
        BookTaskOption.self
      )
    }
    let storeURL = containerURL
      .appendingPathComponent("Library/Application Support", isDirectory: true)
      .appendingPathComponent("default.store")
    return ModelConfiguration(url: storeURL)
  }

  static func makeContainer() throws -> ModelContainer {
    try ModelContainer(for: schema, configurations: [makeConfiguration()])
  }
}
