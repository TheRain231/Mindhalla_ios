import AppIntents
import SwiftData
import WidgetKit

struct QuoteCollectionEntity: AppEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(
    name: LocalizedStringResource("Widget.Collection.TypeName", defaultValue: "Quote Collection")
  )
  static let defaultQuery = QuoteCollectionQuery()

  let id: String
  let title: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)")
  }
}

struct QuoteCollectionQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [QuoteCollectionEntity] {
    try allCollections().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [QuoteCollectionEntity] {
    try allCollections()
  }

  private func allCollections() throws -> [QuoteCollectionEntity] {
    #if DEBUG
    return QuoteCollection.mocks().map { QuoteCollectionEntity(id: $0.id, title: $0.title) }
    #else
    let container = try SharedModelStore.makeContainer()
    let context = ModelContext(container)
    let collections = try context.fetch(FetchDescriptor<QuoteCollection>())
    return collections.map { QuoteCollectionEntity(id: $0.id, title: $0.title) }
    #endif
  }
}

struct QuoteAppIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = .init("Widget.Intent.Title", defaultValue: "Quote Widget")
  static let description = IntentDescription(LocalizedStringResource("Widget.Intent.Description", defaultValue: "Shows quotes from your saved collections."))

  @Parameter(title: LocalizedStringResource("Widget.Intent.CollectionParam", defaultValue: "Collection"), optionsProvider: CollectionOptionsProvider())
  var collection: QuoteCollectionEntity?

  struct CollectionOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [QuoteCollectionEntity] {
      try await QuoteCollectionQuery().suggestedEntities()
    }
  }
}
