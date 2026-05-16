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
    
    @Published private(set) var loginSucceeded: Bool = false
    
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
            loginSucceeded = false
            defer { isLoading = false }
            
            do {
                try await supabase.auth.signIn(email: email, password: password)
                loginSucceeded = true
            } catch {
                if let authError = error as? AuthError {
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func clearLoginSuccess() {
        loginSucceeded = false
    }

    func needsPlacementTest() async -> Bool {
        do {
            let user = try await supabase.auth.user()
            return !UserDefaults.standard.bool(forKey: "placement_done_\(user.id)")
        } catch {
            return true
        }
    }
}
