//
//  BookTasksView.swift
//  Synapps
//
//  Created by Codex on 28.04.2026.
//

import SwiftUI

struct BookTasksView: View {
  @StateObject var viewModel: ViewModel

  var body: some View {
    Group {
      switch viewModel.screenState {
      case .loading:
        ProgressView("BookTasks.Loading")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        tasksList(response: response)
      }
    }
    .navigationTitle("BookTasks.Navigation.Title")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.fetchIfNeeded()
    }
    .refreshable {
      await viewModel.forceReload()
    }
  }

  private func tasksList(response: BookTasksResponse) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        progressCard(response: response)

        if response.tasks.isEmpty {
          waitingTasksCard
        } else {
          ForEach(response.tasks) { task in
            taskCard(task)
          }
        }
      }
      .padding()
    }
    .background(Color(.systemGroupedBackground))
  }

  private var waitingTasksCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("BookTasks.Waiting.Title")
        .font(.headline)
      Text("BookTasks.Waiting.Description")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
  }

  private func progressCard(response: BookTasksResponse) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("BookTasks.Progress.Title")
        .font(.headline)
      ProgressView(value: response.progress)
      Text(chaptersProcessedText(processed: response.processedChapters, total: response.totalChapters))
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
  }

  private func taskCard(_ task: BookTask) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(task.title)
        .font(.headline)

      ForEach(task.options) { option in
        Button {
          viewModel.selectOption(option.id, for: task.id)
        } label: {
          HStack {
            Text(option.text)
              .multilineTextAlignment(.leading)
              .foregroundStyle(.primary)
            Spacer()
            if viewModel.selectedOptionId(for: task.id) == option.id {
              Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "9B60E9"))
            }
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(viewModel.selectedOptionId(for: task.id) == option.id ? Color(hex: "F4ECFF") : Color(.tertiarySystemGroupedBackground))
          )
        }
        .buttonStyle(.plain)
      }

      if let selectedOptionId = viewModel.selectedOptionId(for: task.id) {
        let isCorrect = task.correctOptionIds.contains(selectedOptionId)
        VStack(alignment: .leading, spacing: 6) {
          Text(isCorrect ? "BookTasks.Result.Correct" : "BookTasks.Result.Incorrect")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isCorrect ? .green : .orange)
          Text(hintText(task.hint))
            .font(.footnote)
            .foregroundStyle(.secondary)
          Text(task.explanation)
            .font(.footnote)
        }
      }
    }
    .padding()
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
  }

  private func chaptersProcessedText(processed: Int, total: Int) -> String {
    String(
      format: NSLocalizedString("BookTasks.Progress.ChaptersProcessed", comment: "Shows processed and total chapters in tasks generation"),
      locale: Locale.current,
      processed,
      total
    )
  }

  private func hintText(_ hint: String) -> String {
    String(
      format: NSLocalizedString("BookTasks.Hint.Format", comment: "Prefix for task hint"),
      locale: Locale.current,
      hint
    )
  }
}

#if DEBUG
#Preview {
  BookTasksView(viewModel: BookTasksView.ViewModel(bookId: "preview", networkManager: MockNetworkManager()))
}
#endif
