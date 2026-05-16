//
//  SignUpView.swift
//  AdaptLingo
//
//  Created by Sergey on 03.02.2026.
//

import SwiftUI

struct SignUpView: View {
    let initialEmail: String
    let onSignUpSuccess: () -> Void
    var onCancel: (() -> Void)?

    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
        ZStack {
            appGradient.ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 100, y: -220)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 0).frame(maxHeight: 120)

                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.primary)
                        Text("Регистрация")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Создайте аккаунт и начинайте учить язык")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        glassField {
                            TextField("Никнейм", text: $viewModel.nickname)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundStyle(.primary)
                        }

                        glassField {
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundStyle(.primary)
                        }

                        glassField {
                            SecureField("Пароль (мин. 8 символов)", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .foregroundStyle(.primary)
                        }

                        glassField {
                            SecureField("Подтвердите пароль", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .foregroundStyle(.primary)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(Color(red: 1, green: 0.5, blue: 0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: { viewModel.signUp() }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Зарегистрироваться").fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: viewModel.isFormValid
                                        ? [Color(red:0.38,green:0.3,blue:1), Color(red:0.6,green:0.2,blue:0.9)]
                                        : [Color.primary.opacity(0.12), Color.primary.opacity(0.12)],
                                    startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    onCancel?() ?? onSignUpSuccess()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        }
        .onAppear { viewModel.email = initialEmail }
        .onChange(of: viewModel.registrationSucceeded) { _, succeeded in
            if succeeded { onSignUpSuccess(); viewModel.clearSignUpSuccess() }
        }
    }

    private func glassField<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
}
