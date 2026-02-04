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

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                    Text("Регистрация")
                        .font(.title2.weight(.bold))
                    Text("Создайте аккаунт и начинайте изучать новый язык!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("name@example.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пароль")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("Минимум 8 символов", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Подтверждение пароля")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SecureField("Повторите пароль", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }

                    Button(action: { viewModel.signUp() }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Зарегистрироваться")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.isFormValid ? Color.accentColor : Color.accentColor.opacity(0.4))
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
                )

                Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .onAppear {
                viewModel.email = initialEmail
            }
            .onChange(of: viewModel.registrationSucceeded) { _, succeeded in
                if succeeded {
                    onSignUpSuccess()
                    viewModel.clearSuccess()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onCancel?() ?? onSignUpSuccess()
                    }
                }
            }
        }
    }
}

//#Preview {
//    SignUpView(initialEmail: "3123@mail.ru", onSignUpSuccess: { }, onCancel: nil)
//}
