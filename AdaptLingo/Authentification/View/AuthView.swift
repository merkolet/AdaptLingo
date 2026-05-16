import SwiftUI
import Supabase

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isShowingSignUp: Bool = false

    @State private var isShowingMain: Bool = false
    @State private var isShowingResetPassword = false
    @State private var isShowingPlacementTest = false
    @State private var isShowingLanguageSelect = false
    @State private var languageSelected = false
    @State private var shouldOpenMainAfterSignUp: Bool = false

    @State private var isCheckingSession = true
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // MARK: Фон — адаптивный градиент
            LinearGradient.appBackground(colorScheme)
            .ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -80, y: -180)

            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 120, y: 240)

            // MARK: Основной контент
            ScrollView(showsIndicators: false) {
                VStack(spacing: 36) {

                    VStack(spacing: 10) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 52, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(.bottom, 2)
                        Text("AdaptLingo")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Учи языки с адаптивным AI")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 72)

                    // MARK: Glass-карточка
                    VStack(spacing: 0) {
                        if isCheckingSession {
                            VStack(spacing: 14) {
                                ProgressView().scaleEffect(1.1)
                                Text("Загрузка…")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            VStack(spacing: 16) {
                                glassField {
                                    TextField("Email", text: $viewModel.email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundStyle(.primary)
                                }

                                VStack(spacing: 6) {
                                    glassField {
                                        SecureField("Пароль", text: $viewModel.password)
                                            .textContentType(.password)
                                            .foregroundStyle(.primary)
                                    }
                                    HStack {
                                        Spacer()
                                        Button {
                                            isShowingResetPassword = true
                                        } label: {
                                            Text("Забыли пароль?")
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }

                                if let error = viewModel.errorMessage {
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundStyle(Color(red: 1, green: 0.5, blue: 0.5))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Button(action: { viewModel.login() }) {
                                    Group {
                                        if viewModel.isLoading {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Войти").fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            colors: viewModel.isFormValid
                                                ? [Color(red: 0.38, green: 0.3, blue: 1), Color(red: 0.6, green: 0.2, blue: 0.9)]
                                                : [Color.primary.opacity(0.12), Color.primary.opacity(0.12)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .disabled(!viewModel.isFormValid || viewModel.isLoading)

                                HStack(spacing: 10) {
                                    Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
                                    Text("или").font(.caption).foregroundStyle(.secondary)
                                    Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
                                }

                                Button { isShowingSignUp = true } label: {
                                    Text("Зарегистрироваться")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .foregroundStyle(.primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.primary.opacity(0.25), lineWidth: 1.5)
                                        )
                                }
                            }
                            .padding(24)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .task { await checkExistingSession() }
        .onChange(of: viewModel.loginSucceeded) { _, succeeded in
            if succeeded {
                Task {
                    if await viewModel.needsPlacementTest() {
                        isShowingPlacementTest = true
                    } else {
                        isShowingMain = true
                    }
                    viewModel.clearLoginSuccess()
                }
            }
        }
        .onChange(of: isShowingSignUp) { _, isPresented in
            if !isPresented && shouldOpenMainAfterSignUp {
                shouldOpenMainAfterSignUp = false
                isShowingLanguageSelect = true
            }
        }
        .onChange(of: isShowingLanguageSelect) { _, isPresented in
            if !isPresented && languageSelected {
                languageSelected = false
                isShowingPlacementTest = true
            }
        }
        .fullScreenCover(isPresented: $isShowingSignUp) {
            SignUpView(
                initialEmail: viewModel.email,
                onSignUpSuccess: {
                    viewModel.password = ""
                    shouldOpenMainAfterSignUp = true
                    isShowingSignUp = false
                },
                onCancel: { isShowingSignUp = false }
            )
        }
        .fullScreenCover(isPresented: $isShowingResetPassword) {
            ResetPasswordView(
                initalEmail: viewModel.email,
                onClose: { isShowingResetPassword = false}
            )
        }
        .fullScreenCover(isPresented: $isShowingLanguageSelect) {
            LanguageSelectView(onSelect: {
                languageSelected = true
                isShowingLanguageSelect = false
            })
        }
        .fullScreenCover(isPresented: $isShowingPlacementTest) {
            PlacementTestView(onComplete: {
                isShowingMain = true
            })
        }
        .fullScreenCover(isPresented: $isShowingMain) {
            MainView()
        }
        .onChange(of: isShowingMain) { _, isPresented in
            if !isPresented {
                isCheckingSession = false
            }
        }
    }

    // MARK: - Проверка существующей сессии при запуске

    private func checkExistingSession() async {
        do {
            let _ = try await supabase.auth.user()

            if await viewModel.needsPlacementTest() {
                isShowingPlacementTest = true
            } else {
                isShowingMain = true
            }
            return
        } catch {
        }
        isCheckingSession = false
    }
}

private extension AuthView {
    func glassField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    AuthView()
}
