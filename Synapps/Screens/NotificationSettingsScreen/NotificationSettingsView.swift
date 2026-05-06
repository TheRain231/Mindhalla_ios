import SwiftUI

struct NotificationSettingsView: View {
  @ObservedObject var viewModel: ProfileView.ViewModel

  var body: some View {
    List {
      timeSection
      goalSection
      intervalsSection
    }
    .navigationTitle("NotificationSettings.Title")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Time

  private var timeSection: some View {
    Section("NotificationSettings.Section.Time") {
      DatePicker(
        "NotificationSettings.TimeLabel",
        selection: notificationTimeBinding,
        displayedComponents: .hourAndMinute
      )
    }
  }

  private var notificationTimeBinding: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          bySettingHour: viewModel.studySettings.notificationHour,
          minute: viewModel.studySettings.notificationMinute,
          second: 0,
          of: .now
        ) ?? .now
      },
      set: { date in
        viewModel.updateNotificationTime(
          hour: Calendar.current.component(.hour, from: date),
          minute: Calendar.current.component(.minute, from: date)
        )
      }
    )
  }

  // MARK: - Goal

  private var goalSection: some View {
    Section("NotificationSettings.Section.Goal") {
      Picker("NotificationSettings.Goal.Mode", selection: goalModeBinding) {
        Text("NotificationSettings.Goal.Cards").tag(StudySettings.GoalMode.cards)
        Text("NotificationSettings.Goal.Minutes").tag(StudySettings.GoalMode.minutes)
      }
      .pickerStyle(.segmented)

      Stepper(goalLabel, value: goalValueBinding, in: viewModel.studySettings.goalRange, step: 5)
    }
  }

  private var goalModeBinding: Binding<StudySettings.GoalMode> {
    Binding(
      get: { viewModel.studySettings.goalMode },
      set: { viewModel.updateGoalMode($0) }
    )
  }

  private var goalValueBinding: Binding<Int> {
    Binding(
      get: { viewModel.studySettings.goalValue },
      set: { viewModel.updateGoalValue($0) }
    )
  }

  private var goalLabel: String {
    let v = viewModel.studySettings.goalValue
    switch viewModel.studySettings.goalMode {
    case .cards:
      return String(format: String(localized: "NotificationSettings.Goal.Format.Cards"), v)
    case .minutes:
      return String(format: String(localized: "NotificationSettings.Goal.Format.Minutes"), v)
    }
  }

  // MARK: - Intervals

  private var intervalsSection: some View {
    Section {
      ForEach(SpacedRepetitionScheduler.availableIntervals, id: \.self) { days in
        intervalRow(days: days)
      }
    } header: {
      Text("NotificationSettings.Section.Intervals")
    } footer: {
      Text("NotificationSettings.Intervals.Footer")
    }
  }

  private func intervalRow(days: Int) -> some View {
    let isSelected = viewModel.studySettings.intervals.contains(days)
    let isLast = viewModel.studySettings.intervals.count == 1 && isSelected

    return Button {
      if !isLast { viewModel.toggleInterval(days) }
    } label: {
      HStack {
        Text(intervalLabel(days))
          .foregroundStyle(isLast ? .secondary : .primary)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(Color(hex: "9B60E9"))
        }
      }
    }
  }

  private func intervalLabel(_ days: Int) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day]
    formatter.unitsStyle = .full
    return formatter.string(from: DateComponents(day: days)) ?? "\(days)"
  }
}

#Preview {
  NavigationStack {
    NotificationSettingsView(viewModel: ProfileView.ViewModel())
  }
}
