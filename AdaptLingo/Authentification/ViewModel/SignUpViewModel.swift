//
//  SignUpViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 03.02.2026.
//

import Foundation
import Supabase
import Combine

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    /// Флаг успешной регистрации: View подписывается и при true вызывает onSignUpSuccess, затем clearSuccess().
    @Published private(set) var registrationSucceeded: Bool = false

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
    }

    // MARK: - Actions

    func signUp() {
        guard !isLoading, isFormValid else { return }

        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                _ = try await supabase.auth.signUp(email: email, password: password)
                registrationSucceeded = true
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Вызывается из View после реакции на registrationSucceeded, чтобы сбросить флаг.
    func clearSuccess() {
        registrationSucceeded = false
    }
}
