//
//  AuthViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 03.02.2026.
//

import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        email.contains("@")
    }
    
    // MARK: - Actions
    
    func login() {
        guard !isLoading, isFormValid else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            
            do {
                try await supabase.auth.signIn(email: email, password: password)
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func forgotPassword() {
        // TODO: восстановление пароля через email (Supabase reset password)
    }
}
