//
//  SpacedRepetitionScheduler.swift
//  Synapps
//

import Foundation
import UserNotifications

enum SpacedRepetitionScheduler {
  static let availableIntervals = [1, 2, 3, 5, 7, 10, 14, 21, 30]
  private static let idPrefix = "synapps.sr"

  // MARK: - Schedule

  static func schedule(settings: StudySettings, from referenceDate: Date = .now) {
    let center = UNUserNotificationCenter.current()
    removeAll(from: center)

    let bodies = localizedBodies()

    for (index, days) in settings.intervals.sorted().enumerated() {
      guard let fireDate = Calendar.current.date(byAdding: .day, value: days, to: referenceDate)
      else { continue }

      var dc = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
      dc.hour = settings.notificationHour
      dc.minute = settings.notificationMinute

      let content = UNMutableNotificationContent()
      content.title = String(localized: "Profile.Notifications.Content.Title")
      content.body = bodies[index % bodies.count]
      content.sound = .default

      let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
      let request = UNNotificationRequest(
        identifier: "\(idPrefix).\(days)",
        content: content,
        trigger: trigger
      )
      center.add(request)
    }

    UserDefaults.standard.set(referenceDate, forKey: UserDefaultsKeys.lastStudyDateKey)
    print("[SR] scheduled \(settings.intervals.count) notifications from \(referenceDate)")
  }

  // MARK: - Reschedule on foreground

  static func rescheduleIfNeeded() {
    guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsEnabledKey) else { return }
    let settings = StudySettings.load()
    let ref = (UserDefaults.standard.object(forKey: UserDefaultsKeys.lastStudyDateKey) as? Date) ?? .now
    let maxDays = settings.intervals.max() ?? 30
    guard let maxDate = Calendar.current.date(byAdding: .day, value: maxDays, to: ref) else { return }
    if maxDate < .now {
      print("[SR] all notifications fired, rescheduling from today")
      schedule(settings: settings)
    }
  }

  // MARK: - Record study session

  /// Call this when the user actively studies cards — resets the SR clock.
  static func recordStudySession() {
    guard UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsEnabledKey) else { return }
    let settings = StudySettings.load()
    schedule(settings: settings)
  }

  // MARK: - Remove

  static func removeAll() {
    removeAll(from: UNUserNotificationCenter.current())
  }

  private static func removeAll(from center: UNUserNotificationCenter) {
    let ids = availableIntervals.map { "\(idPrefix).\($0)" }
    center.removePendingNotificationRequests(withIdentifiers: ids)
  }

  /// Литеральные ключи нужны, чтобы `String.LocalizationValue` не пытался превратить
  /// интерполяцию `\(i)` в format-плейсхолдер `%lld` и сломать поиск перевода.
  private static func localizedBodies() -> [String] {
    [
      String(localized: "Profile.Notifications.Content.Body.1"),
      String(localized: "Profile.Notifications.Content.Body.2"),
      String(localized: "Profile.Notifications.Content.Body.3"),
      String(localized: "Profile.Notifications.Content.Body.4"),
      String(localized: "Profile.Notifications.Content.Body.5"),
      String(localized: "Profile.Notifications.Content.Body.6"),
      String(localized: "Profile.Notifications.Content.Body.7"),
    ]
  }
}
