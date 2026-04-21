//
//  StudySettings.swift
//  Synapps
//

import Foundation

struct StudySettings: Codable, Equatable {
  enum GoalMode: String, Codable, CaseIterable {
    case cards
    case minutes
  }

  var goalMode: GoalMode
  var goalValue: Int
  var intervals: [Int]
  var notificationHour: Int
  var notificationMinute: Int

  static let `default` = StudySettings(
    goalMode: .cards,
    goalValue: 20,
    intervals: [1, 3, 7, 14, 30],
    notificationHour: 10,
    notificationMinute: 0
  )

  static func load() -> StudySettings {
    guard
      let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.studySettingsKey),
      let settings = try? JSONDecoder().decode(StudySettings.self, from: data)
    else { return .default }
    return settings
  }

  func save() {
    guard let data = try? JSONEncoder().encode(self) else { return }
    UserDefaults.standard.set(data, forKey: UserDefaultsKeys.studySettingsKey)
  }

  var goalRange: ClosedRange<Int> {
    switch goalMode {
    case .cards: 5...100
    case .minutes: 5...120
    }
  }
}
