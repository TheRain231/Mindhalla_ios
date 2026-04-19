import SwiftUI
import WidgetKit

struct QuoteWidgetExtension: Widget {
  let kind: String = "QuoteWidgetExtension"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: QuoteAppIntent.self, provider: QuoteTimelineProvider()) { entry in
      QuoteEntryView(entry: entry)
    }
  }
}
