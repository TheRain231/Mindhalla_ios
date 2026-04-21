import PhotosUI
import SwiftData
import SwiftUI

struct ProfileView: View {
  @StateObject private var viewModel = ViewModel()
  @Query private var books: [BookMetaResponse]
  @Query private var cards: [Card]
  @Query private var collections: [QuoteCollection]

  var body: some View {
    NavigationStack {
      List {
        Section {
          headerRow
        }

        Section("Profile.Section.Statistics") {
          statRow(icon: "book.closed", label: "Profile.Stat.Books", value: books.count)
          statRow(icon: "rectangle.on.rectangle", label: "Profile.Stat.Cards", value: cards.count)
          statRow(icon: "folder", label: "Profile.Stat.Collections", value: collections.count)
        }

        Section("Profile.Section.Settings") {
          Toggle(isOn: notificationsBinding) {
            Label("Profile.Notifications.Toggle", systemImage: "bell")
          }
          .tint(Color(hex: "9B60E9"))

          if viewModel.notificationsEnabled {
            NavigationLink {
              NotificationSettingsView(viewModel: viewModel)
            } label: {
              Label("NotificationSettings.Title", systemImage: "bell.badge")
            }
          }
        }

        Section("Profile.Section.App") {
          HStack {
            Label("Profile.App.Version", systemImage: "info.circle")
            Spacer()
            Text(viewModel.appVersion)
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Profile.Title")
      .onChange(of: viewModel.photosPickerItem) { _, item in
        Task { await viewModel.loadAvatar(from: item) }
      }
      .alert("Profile.Notifications.Alert.Title", isPresented: $viewModel.showNotificationsDeniedAlert) {
        Button("Profile.Notifications.Alert.OpenSettings") { viewModel.openAppSettings() }
        Button("Cancel", role: .cancel) { viewModel.notificationsEnabled = false }
      } message: {
        Text("Profile.Notifications.Alert.Message")
      }
    }
  }

  // MARK: - Header

  private var headerRow: some View {
    HStack(spacing: 16) {
      PhotosPicker(selection: $viewModel.photosPickerItem, matching: .images) {
        avatarView
          .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.white)
              .padding(5)
              .background(Color(hex: "9B60E9"), in: Circle())
              .offset(x: 2, y: 2)
          }
      }
      .buttonStyle(.plain)

      if viewModel.isEditingNickname {
        TextField("Profile.Nickname.Placeholder", text: $viewModel.nicknameInput)
          .font(.title3.weight(.semibold))
          .onSubmit { viewModel.saveNickname() }
          .submitLabel(.done)
      } else {
        Text(viewModel.nickname.isEmpty ? String(localized: "Profile.NoName") : viewModel.nickname)
          .font(.title3.weight(.semibold))
        Spacer()
        Button { viewModel.startEditingNickname() } label: {
          Image(systemName: "pencil")
            .foregroundStyle(Color(hex: "9B60E9"))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 4)
  }

  private var avatarView: some View {
    Group {
      if let image = viewModel.avatarImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 56, height: 56)
          .clipShape(Circle())
      } else {
        ZStack {
          Circle()
            .fill(Color(hex: "9B60E9"))
            .frame(width: 56, height: 56)
          Text(viewModel.avatarInitial)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.white)
        }
      }
    }
  }

  private var notificationsBinding: Binding<Bool> {
    Binding(
      get: { viewModel.notificationsEnabled },
      set: { viewModel.setNotifications($0) }
    )
  }

  private func statRow(icon: String, label: LocalizedStringKey, value: Int) -> some View {
    HStack {
      Label(label, systemImage: icon)
      Spacer()
      Text("\(value)")
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }
}

#Preview {
  let factory = MockViewModelFactory()
  ProfileView()
    .modelContainer(factory.modelContainer)
}
