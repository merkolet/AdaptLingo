//
//  ResetPasswordViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 06.04.2026.
//

import Foundation
import Supabase
import Combine

@MainActor
final class ResetPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
    
    func sendResetEmail() {
        guard !isLoading, isFormValid else {
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            
            do {
                try await supabase.auth.resetPasswordForEmail(
                    email,
                    redirectTo: URL(string: "adaptlingo://auth/callback")!
                )
                successMessage = "Ссылка отправлена на \(email)"
                isLoading = false
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}
