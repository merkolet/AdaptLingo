//
//  SupabaseIntegrationTests.swift
//  AdaptLingoTests
//
//  Created by Sergey on 15.04.2026.
//
//  Интеграционные тесты для Supabase-бэкенда.

import XCTest
@testable import AdaptLingo
import Supabase

final class SupabaseIntegrationTests: XCTestCase {

    // MARK: - Тестовый аккаунт

    private static let testEmail = "adaptlingo.test.integration@yopmail.com"
    private static let testPassword = "TestPass2026!"

    // MARK: - Глобальный setUp

    override class func setUp() {
        super.setUp()
        let exp = XCTestExpectation(description: "create test user")
        Task {
            _ = try? await supabase.auth.signUp(
                email: testEmail,
                password: testPassword
            )
            try? await supabase.auth.signOut()
            exp.fulfill()
        }
        XCTWaiter().wait(for: [exp], timeout: 30)
    }

    // MARK: - Helpers

    private func signIn() async throws {
        try await supabase.auth.signIn(
            email: Self.testEmail,
            password: Self.testPassword
        )
        addTeardownBlock {
            try? await supabase.auth.signOut()
        }
    }

    // MARK: - Auth: регистрация нового пользователя

    func testSignUpCreatesUser() async throws {
        let uniqueEmail = "adaptlingo.new.\(UUID().uuidString.prefix(8).lowercased())@yopmail.com"
        addTeardownBlock { try? await supabase.auth.signOut() }

        let response = try await supabase.auth.signUp(
            email: uniqueEmail,
            password: "NewUser2026!"
        )
        XCTAssertNotNil(response.user)
        XCTAssertEqual(response.user.email, uniqueEmail)
    }

    // MARK: - Auth: вход с корректными данными

    func testSignInWithValidCredentialsSucceeds() async throws {
        try await signIn()
        let user = try await supabase.auth.user()
        XCTAssertEqual(user.email, Self.testEmail)
    }

    // MARK: - Auth: вход с неверным паролем

    func testSignInWithWrongPasswordThrows() async {
        do {
            try await supabase.auth.signIn(
                email: Self.testEmail,
                password: "WrongPassword999!"
            )
            XCTFail("Ожидалась ошибка при неверном пароле")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Auth: запрос сброса пароля

    func testResetPasswordEmailDoesNotThrow() async throws {
        try await supabase.auth.resetPasswordForEmail(
            Self.testEmail,
            redirectTo: URL(string: "adaptlingo://auth/callback")!
        )
    }

    // MARK: - Auth: выход из аккаунта

    func testSignOutSucceeds() async throws {
        try await signIn()
        try await supabase.auth.signOut()

        do {
            _ = try await supabase.auth.user()
            XCTFail("После signOut сессия должна быть закрыта")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - user_profiles: чтение профиля

    func testUserProfileIsReadable() async throws {
        try await signIn()
        let user = try await supabase.auth.user()

        struct ProfileRow: Decodable {
            let id: String
            let level: String?
            let xp: Int?
            let streak_days: Int?
        }

        let rows: [ProfileRow] = try await supabase
            .from("user_profiles")
            .select("id, level, xp, streak_days")
            .eq("id", value: user.id.uuidString)
            .execute()
            .value

        XCTAssertFalse(rows.isEmpty, "Профиль тестового пользователя должен существовать")
        XCTAssertEqual(rows.first?.id, user.id.uuidString)
    }

    // MARK: - user_profiles: обновление display_name

    func testUserProfileDisplayNameUpdate() async throws {
        try await signIn()
        let user    = try await supabase.auth.user()
        let newName = "IntegrationUser_\(Int.random(in: 1000...9999))"

        try await supabase
            .from("user_profiles")
            .update(["display_name": newName])
            .eq("id", value: user.id.uuidString)
            .execute()

        struct NameRow: Decodable { let display_name: String? }

        let rows: [NameRow] = try await supabase
            .from("user_profiles")
            .select("display_name")
            .eq("id", value: user.id.uuidString)
            .execute()
            .value

        XCTAssertEqual(rows.first?.display_name, newName,
                       "display_name должен обновиться в базе")
    }

    // MARK: - exercise_history: вставка записи

    func testInsertExerciseHistoryRecord() async throws {
        try await signIn()
        let user = try await supabase.auth.user()
        let testQuestion = "[TEST] What is the plural of 'mouse'?"

        struct HistoryInsert: Encodable {
            let user_id: String
            let exercise_type: String
            let question: String
            let correct_answer: String
            let user_answer: String
            let is_correct: Bool
        }

        try await supabase
            .from("exercise_history")
            .insert(HistoryInsert(
                user_id: user.id.uuidString,
                exercise_type: "multiple_choice",
                question: testQuestion,
                correct_answer: "mice",
                user_answer: "mice",
                is_correct: true
            ))
            .execute()

        struct HistRow: Decodable { let question: String; let is_correct: Bool }

        let rows: [HistRow] = try await supabase
            .from("exercise_history")
            .select("question, is_correct")
            .eq("user_id", value: user.id.uuidString)
            .eq("question", value: testQuestion)
            .execute()
            .value

        XCTAssertFalse(rows.isEmpty, "Запись должна появиться в таблице")
        XCTAssertTrue(rows.first?.is_correct ?? false)

        try await supabase
            .from("exercise_history")
            .delete()
            .eq("user_id", value: user.id.uuidString)
            .eq("question", value: testQuestion)
            .execute()
    }

    // MARK: - exercise_history: запрос истории пользователя

    func testQueryExerciseHistorySucceeds() async throws {
        try await signIn()
        let user = try await supabase.auth.user()

        struct HistRow: Decodable {
            let is_correct   : Bool
            let exercise_type: String
        }

        let rows: [HistRow] = try await supabase
            .from("exercise_history")
            .select("is_correct, exercise_type")
            .eq("user_id", value: user.id.uuidString)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value

        XCTAssertNotNil(rows)
    }

    // MARK: - placement_results: вставка результата теста

    func testInsertPlacementResult() async throws {
        try await signIn()
        let user = try await supabase.auth.user()
        let testReason = "[TEST] integration_\(UUID().uuidString.prefix(8))"

        struct PlacementInsert: Encodable {
            let user_id: String
            let assigned_level: String
            let score: Int
            let total: Int
            let accuracy_pct: Int
            let reason: String
        }

        try await supabase
            .from("placement_results")
            .insert(PlacementInsert(
                user_id: user.id.uuidString,
                assigned_level: "B1",
                score: 9,
                total: 15,
                accuracy_pct: 60,
                reason: testReason
            ))
            .execute()

        struct PlacementRow: Decodable { let assigned_level: String; let score: Int }

        let rows: [PlacementRow] = try await supabase
            .from("placement_results")
            .select("assigned_level, score")
            .eq("user_id", value: user.id.uuidString)
            .eq("reason", value: testReason)
            .execute()
            .value

        XCTAssertFalse(rows.isEmpty, "Результат placement-теста должен быть записан")
        XCTAssertEqual(rows.first?.assigned_level, "B1")
        XCTAssertEqual(rows.first?.score, 9)

        try await supabase
            .from("placement_results")
            .delete()
            .eq("user_id", value: user.id.uuidString)
            .eq("reason", value: testReason)
            .execute()
    }
}
