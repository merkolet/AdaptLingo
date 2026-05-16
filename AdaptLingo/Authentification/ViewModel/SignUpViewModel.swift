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
    @Published var nickname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published private(set) var registrationSucceeded: Bool = false

    var isFormValid: Bool {
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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
                let response = try await supabase.auth.signUp(email: email, password: password)
                let userId = response.user.id.uuidString
                let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                try await supabase
                    .from("user_profiles")
                    .upsert(["id": userId, "display_name": trimmed])
                    .execute()
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

    func clearSignUpSuccess() {
        registrationSucceeded = false
    }
}
