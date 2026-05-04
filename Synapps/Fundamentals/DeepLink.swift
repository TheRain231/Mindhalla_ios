import Foundation

enum DeepLink: Equatable {
  case collection(id: String)
  case saved
  case savedByBook(bookId: String)

  init?(url: URL) {
    guard url.scheme == "synapps" else { return nil }
    switch url.host {
    case "collection":
      let id = url.pathComponents.dropFirst().first ?? ""
      guard !id.isEmpty else { return nil }
      self = .collection(id: id)
    case "saved":
      self = .saved
    default:
      return nil
    }
  }
}
