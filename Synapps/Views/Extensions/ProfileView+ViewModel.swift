import PhotosUI
import SwiftUI
import UserNotifications

extension ProfileView {
  final class ViewModel: ObservableObject {
    @Published var nickname: String {
      didSet { UserDefaults.standard.set(nickname, forKey: UserDefaultsKeys.nicknameKey) }
    }

    @Published var notificationsEnabled: Bool {
      didSet { UserDefaults.standard.set(notificationsEnabled, forKey: UserDefaultsKeys.notificationsEnabledKey) }
    }

    @Published var studySettings: StudySettings
    @Published var isEditingNickname = false
    @Published var nicknameInput = ""
    @Published var avatarImage: UIImage?
    @Published var photosPickerItem: PhotosPickerItem?
    @Published var showNotificationsDeniedAlert = false

    init() {
      nickname = UserDefaults.standard.string(forKey: UserDefaultsKeys.nicknameKey) ?? ""
      notificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsEnabledKey)
      studySettings = StudySettings.load()
      avatarImage = AvatarStore.load()
    }

    var appVersion: String {
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var avatarInitial: String {
      nickname.first.map { String($0).uppercased() } ?? "?"
    }

    // MARK: - Nickname

    func startEditingNickname() {
      nicknameInput = nickname
      isEditingNickname = true
    }

    func saveNickname() {
      nickname = nicknameInput.trimmingCharacters(in: .whitespaces)
      isEditingNickname = false
    }

    // MARK: - Avatar

    func loadAvatar(from item: PhotosPickerItem?) async {
      guard let item,
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data) else { return }
      let compressed = image.jpegData(compressionQuality: 0.8).flatMap { UIImage(data: $0) } ?? image
      AvatarStore.save(compressed)
      await MainActor.run { avatarImage = compressed }
    }

    // MARK: - Notifications

    func setNotifications(_ enabled: Bool) {
      if enabled {
        requestAndScheduleNotifications()
      } else {
        SpacedRepetitionScheduler.removeAll()
        notificationsEnabled = false
      }
    }

    // MARK: - Study settings

    func updateGoalMode(_ mode: StudySettings.GoalMode) {
      studySettings.goalMode = mode
      studySettings.goalValue = max(
        studySettings.goalRange.lowerBound,
        min(studySettings.goalValue, studySettings.goalRange.upperBound)
      )
      studySettings.save()
    }

    func updateGoalValue(_ value: Int) {
      studySettings.goalValue = value
      studySettings.save()
    }

    func updateNotificationTime(hour: Int, minute: Int) {
      studySettings.notificationHour = hour
      studySettings.notificationMinute = minute
      studySettings.save()
      if notificationsEnabled { SpacedRepetitionScheduler.schedule(settings: studySettings) }
    }

    func toggleInterval(_ days: Int) {
      if studySettings.intervals.contains(days) {
        guard studySettings.intervals.count > 1 else { return }
        studySettings.intervals.removeAll { $0 == days }
      } else {
        studySettings.intervals.append(days)
      }
      studySettings.save()
      if notificationsEnabled { SpacedRepetitionScheduler.schedule(settings: studySettings) }
    }

    private func requestAndScheduleNotifications() {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
        DispatchQueue.main.async {
          if granted {
            self?.notificationsEnabled = true
            self?.scheduleCardReminders()
          } else {
            self?.notificationsEnabled = false
            self?.showNotificationsDeniedAlert = true
          }
        }
      }
    }

    private func scheduleCardReminders() {
      SpacedRepetitionScheduler.schedule(settings: studySettings)
    }

    func openAppSettings() {
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    }
  }
}

// MARK: - AvatarStore

enum AvatarStore {
  private static var url: URL? {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)
      .first?
      .appendingPathComponent("profile_avatar.jpg")
  }

  static func save(_ image: UIImage) {
    guard let url, let data = image.jpegData(compressionQuality: 0.8) else { return }
    try? data.write(to: url, options: .atomic)
  }

  static func load() -> UIImage? {
    guard let url, let data = try? Data(contentsOf: url) else { return nil }
    return UIImage(data: data)
  }
}
