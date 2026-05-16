//
//  ProfileView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    let onSignOut: () -> Void

    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var imageManager = ProfileImageManager.shared
    @ObservedObject private var translationMode = TranslationModeManager.shared
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showSignOutAlert = false
    @State private var showCoreMLAlert = false
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                appGradient.ignoresSafeArea()

                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: 120, y: 200)

                List {
                    userSection
                    settingsSection
                    accountSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Профиль")
            .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .task { await viewModel.loadProfile() }
            .alert("Переключиться на CoreML?", isPresented: $showCoreMLAlert) {
                Button("Переключить", role: .destructive) {
                    translationMode.mode = .coreML
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Качество перевода значительно ухудшится. Локальная модель работает без интернета, но менее точна.")
            }
            .alert("Выйти из аккаунта?", isPresented: $showSignOutAlert) {
                Button("Выйти", role: .destructive) {
                    Task { await viewModel.signOut(); onSignOut() }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }

    // MARK: - Аватар + имя

    private var userSection: some View {
        Section {
            HStack(spacing: 14) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                            if let img = imageManager.avatarImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .padding(4)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .offset(x: 2, y: 2)
                    }
                }
                .onChange(of: photoPickerItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            imageManager.save(img)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.isLoading {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text(viewModel.displayName.isEmpty ? "Пользователь" : viewModel.displayName)
                            .font(.headline).foregroundStyle(.primary)
                    }
                    Text(viewModel.email).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(glassRowBackground)
        }
    }

    // MARK: - Настройки

    private var settingsSection: some View {
        Section("Настройки") {
            HStack {
                Label("Язык обучения", systemImage: "globe").foregroundStyle(.primary)
                Spacer()
                Text("Английский").foregroundStyle(.secondary)
            }
            .listRowBackground(glassRowBackground)

            Button {
                if translationMode.mode == .llm {
                    showCoreMLAlert = true
                } else {
                    translationMode.mode = .llm
                }
            } label: {
                HStack {
                    Label("Перевод", systemImage: "network")
                    Spacer()
                    Text(translationMode.mode.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .listRowBackground(glassRowBackground)

            NavigationLink {
                EditProfileView(viewModel: viewModel)
            } label: {
                Label("Редактировать профиль", systemImage: "person.crop.circle").foregroundStyle(.primary)
            }
            .listRowBackground(glassRowBackground)

            Picker(selection: Binding(
                get: { themeManager.current },
                set: { themeManager.set($0) }
            )) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Label(theme.displayName, systemImage: theme.icon).tag(theme)
                }
            } label: {
                Label("Тема оформления", systemImage: themeManager.current.icon).foregroundStyle(.primary)
            }
            .listRowBackground(glassRowBackground)
        }
    }

    // MARK: - Аккаунт

    private var accountSection: some View {
        Section {
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                    Spacer()
                }
            }
            .listRowBackground(glassRowBackground)
        }
    }

    private var glassRowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Редактирование профиля

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var localName = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNameSuccess = false
    @State private var showPwSuccess = false

    private var passwordValid: Bool {
        newPassword.count >= 8 && newPassword == confirmPassword
    }
    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && newPassword != confirmPassword
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground(colorScheme).ignoresSafeArea()

            Form {
                // MARK: Имя
                Section {
                    TextField("Отображаемое имя", text: $localName)
                        .autocorrectionDisabled()
                        .foregroundStyle(.primary)
                        .listRowBackground(rowBg)

                    Button {
                        Task {
                            let trimmed = localName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            await viewModel.saveDisplayName(trimmed)
                            if viewModel.errorMessage == nil { showNameSuccess = true }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView().scaleEffect(0.85)
                            } else {
                                Text("Сохранить имя").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .foregroundStyle(.indigo)
                    .disabled(viewModel.isSaving || localName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .listRowBackground(rowBg)
                } header: {
                    Text("Имя").foregroundStyle(.secondary)
                } footer: {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(red:1,green:0.5,blue:0.5))
                            .font(.footnote)
                    } else {
                        Text("Отображается в вашем профиле.").foregroundStyle(.secondary)
                    }
                }

                // MARK: Email
                Section("Email") {
                    Text(viewModel.email).foregroundStyle(.secondary)
                        .listRowBackground(rowBg)
                }

                // MARK: Пароль
                Section {
                    SecureField("Новый пароль (мин. 8 символов)", text: $newPassword)
                        .textContentType(.newPassword)
                        .foregroundStyle(.primary)
                        .listRowBackground(rowBg)

                    SecureField("Подтвердите пароль", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .foregroundStyle(.primary)
                        .listRowBackground(rowBg)

                    Button {
                        Task {
                            await viewModel.updatePassword(newPassword)
                            if viewModel.passwordError == nil {
                                newPassword     = ""
                                confirmPassword = ""
                                showPwSuccess   = true
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isUpdatingPassword {
                                ProgressView().scaleEffect(0.85)
                            } else {
                                Text("Обновить пароль").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .foregroundStyle(passwordValid ? .indigo : .secondary)
                    .disabled(!passwordValid || viewModel.isUpdatingPassword)
                    .listRowBackground(rowBg)
                } header: {
                    Text("Пароль").foregroundStyle(.secondary)
                } footer: {
                    if let error = viewModel.passwordError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(red:1,green:0.5,blue:0.5))
                            .font(.footnote)
                    } else if passwordMismatch {
                        Label("Пароли не совпадают", systemImage: "xmark.circle")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    } else if !newPassword.isEmpty && newPassword.count < 8 {
                        Label("Минимум 8 символов", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Редактировать профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .onAppear { localName = viewModel.displayName }
        .overlay(alignment: .top) {
            if showNameSuccess || showPwSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(showNameSuccess ? "Имя сохранено" : "Пароль обновлён")
                        .fontWeight(.medium).foregroundStyle(.primary)
                }
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showNameSuccess = false
                        showPwSuccess   = false
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showNameSuccess)
        .animation(.easeInOut(duration: 0.3), value: showPwSuccess)
    }

    private var rowBg: some View {
        Color.primary.opacity(0.06)
    }
}

#Preview { ProfileView(onSignOut: {}) }
