//
//  ResetPasswordView.swift
//  AdaptLingo
//
//  Created by Sergey on 06.04.2026.
//

import SwiftUI

struct ResetPasswordView: View {
    let initalEmail: String
    let onClose: () -> Void

    @StateObject private var viewModel = ResetPasswordViewModel()
    @State private var showToast = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
        ZStack {
            appGradient.ignoresSafeArea()

            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -100, y: 200)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 0).frame(maxHeight: 150)
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation.open")
                            .font(.system(size: 44))
                            .foregroundStyle(.primary)
                        Text("Сброс пароля")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("Введите email — пришлём ссылку для сброса")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        glassField {
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundStyle(.primary)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(Color(red:1,green:0.5,blue:0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: { viewModel.sendResetEmail() }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Отправить ссылку").fontWeight(.semibold)
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
        .onAppear { viewModel.email = initalEmail }
        .onChange(of: viewModel.successMessage) { _, msg in
            guard msg != nil else { return }
            withAnimation(.spring(duration: 0.4)) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showToast = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onClose() }
            }
        }
        .overlay(alignment: .top) {
            if showToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(viewModel.successMessage ?? "")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
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

#Preview {
    ResetPasswordView(initalEmail: "test@example.com", onClose: {})
}
