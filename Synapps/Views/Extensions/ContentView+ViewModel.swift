//
//  ContentView+ViewModel.swift
//  Synapps
//
//  Created by Andrey Stepanov on 20.10.2025.
//

import SwiftData
import SwiftUI

extension ContentView {
  final class ViewModel: ObservableObject {
    @Published var selectedTab: TabItem = .home
    @Published var deepLink: DeepLink?
    @Published var pendingDrainToken = UUID()
    @Published var incomingBundleURL: URL?
    @Published var lastImportMessage: String?
    @Published var importError: SynappsBundleImporter.ImportError?

    func handle(url: URL) {
      guard let link = DeepLink(url: url) else { return }
      deepLink = link
      selectedTab = .saved
    }

    func triggerPendingDrain() {
      pendingDrainToken = UUID()
    }

    func openSavedByBook(bookId: String) {
      deepLink = .savedByBook(bookId: bookId)
      selectedTab = .saved
    }

    /// Вызывается из `.onOpenURL` в SynappsApp при получении `.synapps` файла (AirDrop, Files, etc.).
    /// Сохраняет URL в @Published поле; реальный импорт делает ContentView через `.onChange`,
    /// потому что ему нужен `@Environment(\.modelContext)`.
    func handleIncomingBundle(url: URL) {
      incomingBundleURL = url
    }

    @MainActor
    func performImport(url: URL, modelContext: ModelContext) {
      defer { incomingBundleURL = nil }
      do {
        let result = try SynappsBundleImporter.performImport(from: url, modelContext: modelContext)
        switch result.type {
        case .card, .collection: selectedTab = .saved
        case .mindmap:           selectedTab = .mindmaps
        }
        lastImportMessage = makeImportMessage(for: result)
      } catch let err as SynappsBundleImporter.ImportError {
        importError = err
      } catch {
        importError = .unreadable
      }
    }

    private func makeImportMessage(for result: SynappsBundleImporter.ImportResult) -> String {
      switch result.type {
      case .card:
        String(localized: "Import.Toast.Card")
      case .collection:
        String(format: String(localized: "Import.Toast.Collection"), result.insertedCardCount)
      case .mindmap:
        String(format: String(localized: "Import.Toast.MindMap"), result.insertedCardCount)
      }
    }
  }
}

enum TabItem {
  case home
  case saved
  case mindmaps
  case profile
}
