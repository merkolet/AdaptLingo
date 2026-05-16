//
//  NewPasswordViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 13.04.2026.
//

import Foundation
import Supabase
import Combine

@MainActor
final class NewPasswordViewModel: ObservableObject {
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var success: Bool = false

    var isFormValid: Bool {
        newPassword.count >= 8 && newPassword == confirmPassword
    }

    func updatePassword() {
        guard !isLoading, isFormValid else { return }

        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                try await supabase.auth.update(user: UserAttributes(password: newPassword))
                success = true
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
