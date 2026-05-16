//
//  NewPasswordView.swift
//  AdaptLingo
//
//  Created by Sergey on 13.04.2026.
//

import SwiftUI

struct NewPasswordView: View {
    let onClose: () -> Void
    @StateObject private var viewModel = NewPasswordViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
        ZStack {
            appGradient.ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 120, y: 160)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 0).frame(maxHeight: 120)
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.primary)
                        Text("Новый пароль")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Придумайте надёжный пароль для аккаунта")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        glassField {
                            SecureField("Новый пароль", text: $viewModel.newPassword)
                                .textContentType(.newPassword)
                                .foregroundStyle(.primary)
                        }

                        glassField {
                            SecureField("Подтвердите пароль", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .foregroundStyle(.primary)
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(Color(red:1,green:0.5,blue:0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: { viewModel.updatePassword() }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Сохранить пароль").fontWeight(.semibold)
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
                Button { onClose() } label: {
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
        .onChange(of: viewModel.success) { _, ok in if ok { onClose() } }
    }

    private func glassField<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
}
