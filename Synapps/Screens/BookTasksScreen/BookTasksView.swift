import SwiftUI

struct BookTasksDestination: Hashable {
  let bookId: String
}

struct BookTasksView: View {
  @StateObject var viewModel: ViewModel

  private let accent = Color(hex: "9B60E9")
  private let accentSoft = Color(hex: "F4ECFF")

  var body: some View {
    ZStack {
      backgroundGradient.ignoresSafeArea()

      Group {
        switch viewModel.screenState {
        case .loading:
          ProgressView("BookTasks.Loading")
        case .failed:
          ContentUnavailableView(
            "BookTasks.Failed.Title",
            systemImage: "exclamationmark.triangle",
            description: Text("BookTasks.Failed.Description")
          )
        case .empty:
          ContentUnavailableView(
            "BookTasks.Empty.Title",
            systemImage: "doc.text.magnifyingglass",
            description: Text("BookTasks.Empty.Description")
          )
        case let .ready(response):
          if response.tasks.isEmpty {
            waitingView(response: response)
          } else if viewModel.isCompleted {
            completionView(tasks: response.tasks)
          } else {
            taskFlow(response: response)
          }
        }
      }
    }
    .navigationTitle("BookTasks.Navigation.Title")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbarBackground(.hidden, for: .navigationBar)
    .task { await viewModel.fetchIfNeeded() }
    .refreshable { await viewModel.forceReload() }
  }

  // MARK: - Background

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [accentSoft, Color(.systemBackground)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  // MARK: - Task flow

  @ViewBuilder
  private func taskFlow(response: BookTasksResponse) -> some View {
    let safeIndex = min(max(viewModel.currentIndex, 0), response.tasks.count - 1)
    let task = response.tasks[safeIndex]
    let isLast = safeIndex == response.tasks.count - 1

    VStack(spacing: 20) {
      progressHeader(current: safeIndex + 1, total: response.tasks.count)

      ScrollView {
        taskCard(task: task)
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 100)
          .id(task.id)
      }
      .scrollIndicators(.hidden)
    }
    .padding(.vertical, 16)
    .overlay(alignment: .bottom) {
      bottomBar(task: task, taskCount: response.tasks.count, isLast: isLast)
        .padding(.bottom, 16)
    }
  }

  private func progressHeader(current: Int, total: Int) -> some View {
    VStack(spacing: 8) {
      HStack {
        Text("\(current) / \(total)")
          .font(.subheadline.weight(.semibold).monospacedDigit())
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.shuffle()
          }
        } label: {
          Image(systemName: "shuffle")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .padding(8)
            .background(Circle().fill(accentSoft))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("BookTasks.Shuffle")
      }
      ProgressView(value: Double(current), total: Double(total))
        .tint(accent)
    }
    .padding(.horizontal, 20)
  }

  private func taskCard(task: BookTask) -> some View {
    let answered = viewModel.isAnswered(taskId: task.id)
    let isCorrect = viewModel.isFullyCorrect(task: task)
    let isMulti = viewModel.isMultipleChoice(task: task)

    return VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 8) {
        if isMulti {
          Label("BookTasks.MultipleChoice", systemImage: "checklist")
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
        }
        Text(task.title)
          .font(.title3.weight(.semibold))
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack(spacing: 10) {
        ForEach(task.options) { option in
          optionRow(option: option, task: task, answered: answered, isMulti: isMulti)
        }
      }

      if viewModel.isHintVisible(for: task.id), !task.hint.isEmpty {
        hintBox(text: task.hint)
      }

      if answered, !task.explanation.isEmpty {
        explanationBox(isCorrect: isCorrect, explanation: task.explanation)
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 32)
        .fill(Color(.systemBackground))
        .cardShadow()
    }
  }

  private func optionRow(option: BookTaskOption, task: BookTask, answered: Bool, isMulti: Bool) -> some View {
    let isSelected = viewModel.isSelected(optionId: option.id, for: task.id)
    let isCorrectOption = task.correctOptionIds.contains(option.id)

    let background: Color = {
      if !answered { return isSelected ? accentSoft : Color(.systemGray6) }
      if isCorrectOption { return Color(hex: "DCEADD") }
      if isSelected { return Color(hex: "F8DADA") }
      return Color(.systemGray6)
    }()

    return Button {
      viewModel.toggleOption(option.id, for: task)
    } label: {
      HStack(spacing: 12) {
        Text(option.text)
          .font(.body)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
        optionIcon(answered: answered, isSelected: isSelected, isCorrectOption: isCorrectOption, isMulti: isMulti)
      }
      .padding(14)
      .background(RoundedRectangle(cornerRadius: 16).fill(background))
    }
    .buttonStyle(.plain)
    .disabled(answered)
    .animation(.easeInOut(duration: 0.15), value: isSelected)
  }

  @ViewBuilder
  private func optionIcon(answered: Bool, isSelected: Bool, isCorrectOption: Bool, isMulti: Bool) -> some View {
    if !answered {
      if isMulti {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
          .font(.title3)
          .foregroundStyle(isSelected ? accent : .secondary)
      } else {
        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
          .font(.title3)
          .foregroundStyle(isSelected ? accent : .secondary)
      }
    } else if isCorrectOption {
      Image(systemName: "checkmark.circle.fill")
        .font(.title3)
        .foregroundStyle(.green)
    } else if isSelected {
      Image(systemName: "xmark.circle.fill")
        .font(.title3)
        .foregroundStyle(.red)
    } else {
      Image(systemName: isMulti ? "square" : "circle")
        .font(.title3)
        .foregroundStyle(.secondary)
    }
  }

  private func hintBox(text: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "lightbulb.fill")
        .foregroundStyle(Color(hex: "E6A63F"))
      Text(text)
        .font(.footnote)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "FFF6E5")))
  }

  private func explanationBox(isCorrect: Bool, explanation: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(
        isCorrect ? "BookTasks.Result.Correct" : "BookTasks.Result.Incorrect",
        systemImage: isCorrect ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
      )
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(isCorrect ? .green : .orange)
      Text(explanation)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
  }

  private func bottomBar(task: BookTask, taskCount: Int, isLast: Bool) -> some View {
    let answered = viewModel.isAnswered(taskId: task.id)
    let canShowHint = !task.hint.isEmpty && !viewModel.isHintVisible(for: task.id) && !answered
    let isMulti = viewModel.isMultipleChoice(task: task)
    let hasSelection = !viewModel.selectedOptionIds(for: task.id).isEmpty
    let needsCheck = isMulti && !answered

    return HStack(spacing: 12) {
      if canShowHint {
        Button {
          viewModel.showHint(for: task.id)
        } label: {
          Label("BookTasks.Hint.Show", systemImage: "lightbulb")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().stroke(accent, lineWidth: 1.5))
            .background(Capsule().foregroundStyle(.white))
        }
        .buttonStyle(.plain)
      }

      Spacer()

      if needsCheck {
        primaryButton(title: "BookTasks.Check", enabled: hasSelection) {
          viewModel.submit(for: task.id)
        }
      } else {
        primaryButton(title: isLast ? "BookTasks.Finish" : "BookTasks.Next", enabled: answered) {
          viewModel.goToNext(taskCount: taskCount)
        }
      }
    }
    .padding(.horizontal, 20)
  }

  private func primaryButton(title: LocalizedStringKey, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Capsule().fill(enabled ? accent : accent.opacity(0.4)))
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
  }

  // MARK: - Completion

  private func completionView(tasks: [BookTask]) -> some View {
    let correct = viewModel.correctAnswersCount(in: tasks)
    let total = tasks.count

    return VStack(spacing: 20) {
      Spacer()
      Image(systemName: "trophy.fill")
        .font(.system(size: 64))
        .foregroundStyle(accent)
      Text("BookTasks.Completed.Title")
        .font(.title2.weight(.bold))
      Text(scoreText(correct: correct, total: total))
        .font(.title3)
        .foregroundStyle(.secondary)
        .monospacedDigit()
      Spacer()
      Button {
        viewModel.shuffle()
      } label: {
        Label("BookTasks.Completed.Retry", systemImage: "shuffle")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Capsule().fill(accent))
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
  }

  // MARK: - Waiting

  private func waitingView(response: BookTasksResponse) -> some View {
    VStack(spacing: 16) {
      Spacer()
      ProgressView()
        .scaleEffect(1.4)
        .tint(accent)
      Text("BookTasks.Waiting.Title")
        .font(.headline)
      Text("BookTasks.Waiting.Description")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
      VStack(spacing: 8) {
        ProgressView(value: response.progress)
          .tint(accent)
        Text(chaptersProcessedText(processed: response.processedChapters, total: response.totalChapters))
          .font(.footnote.monospacedDigit())
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 40)
      .padding(.top, 8)
      Spacer()
    }
  }

  // MARK: - Formatting

  private func chaptersProcessedText(processed: Int, total: Int) -> String {
    String(
      format: NSLocalizedString("BookTasks.Progress.ChaptersProcessed", comment: ""),
      locale: Locale.current,
      processed,
      total
    )
  }

  private func scoreText(correct: Int, total: Int) -> String {
    String(
      format: NSLocalizedString("BookTasks.Completed.Score", comment: ""),
      locale: Locale.current,
      correct,
      total
    )
  }
}

#if DEBUG
#Preview {
  BookTasksView(viewModel: BookTasksView.ViewModel(bookId: "preview", networkManager: MockNetworkManager()))
}
#endif
