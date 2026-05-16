//
//  ProfileViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation
import Combine
internal import Auth
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var email = ""
    @Published var displayName  = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var isUpdatingPassword = false
    @Published var errorMessage: String?
    @Published var passwordError: String?

    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        } else if let first = displayName.first {
            return String(first).uppercased()
        }
        return email.prefix(1).uppercased()
    }

    // MARK: - Загрузка профиля

    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            email = session.user.email ?? ""
            ProfileImageManager.shared.configure(userId: session.user.id.uuidString)

            struct ProfileRow: Decodable { let display_name: String? }
            let rows: [ProfileRow] = try await supabase
                .from("user_profiles")
                .select("display_name")
                .eq("id", value: session.user.id.uuidString)
                .execute()
                .value

            if let name = rows.first?.display_name, !name.isEmpty {
                displayName = name
            } else if displayName.isEmpty {
                displayName = email.components(separatedBy: "@").first ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Сохранение имени

    func saveDisplayName(_ name: String) async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        do {
            let session = try await supabase.auth.session
            try await supabase
                .from("user_profiles")
                .upsert(["id": session.user.id.uuidString, "display_name": name])
                .execute()
            displayName = name
        } catch {
            let isCancelled = error is CancellationError
                || (error as NSError).code == NSURLErrorCancelled
                || error.localizedDescription.lowercased().contains("cancel")
            if isCancelled {
                displayName = name
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Смена пароля

    func updatePassword(_ newPassword: String) async {
        isUpdatingPassword = true
        passwordError = nil
        defer { isUpdatingPassword = false }
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            passwordError = error.localizedDescription
        }
    }

    // MARK: - Выход

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            ProfileImageManager.shared.reset()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
