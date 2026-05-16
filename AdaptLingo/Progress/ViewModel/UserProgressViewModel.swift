//
//  UserProgressViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation
import Combine
import SwiftUI
import Supabase

// MARK: - Статистика по типу упражнения

struct ExerciseTypeStat {
    let type: String
    let total: Int
    let correct: Int
    var accuracy: Int { total > 0 ? Int(Double(correct) / Double(total) * 100) : 0 }
    var displayName: String {
        switch type {
        case "fill_blank": return "Пропуски"
        case "translation": return "Перевод"
        default: return "Грамматика"
        }
    }
    var icon: String {
        switch type {
        case "fill_blank": return "pencil.line"
        case "translation": return "arrow.left.arrow.right"
        default: return "checkmark.circle"
        }
    }
    var color: Color {
        switch type {
        case "fill_blank": return .blue
        case "translation": return .purple
        default: return .green
        }
    }
}

// MARK: - Запись истории упражнений

struct ExerciseHistoryItem: Identifiable {
    let id = UUID()
    let question: String
    let exerciseType: String
    let isCorrect: Bool
    let correctAnswer: String
    let userAnswer: String
    let explanation: String
    let createdAt: String
}

@MainActor
final class UserProgressViewModel: ObservableObject {
    @Published var level = "A1"
    @Published var xp = 0
    @Published var streakDays = 0
    @Published var totalDone = 0
    @Published var totalCorrect = 0
    @Published var isLoading = false
    @Published var typeStats: [ExerciseTypeStat] = []
    @Published var recentHistory: [ExerciseHistoryItem] = []

    var xpForNextLevel: Int { levelThreshold(after: level) }
    var xpProgress: Double {
        let threshold = Double(xpForNextLevel)
        return threshold > 0 ? min(Double(xp) / threshold, 1.0) : 1.0
    }
    var accuracy: Int {
        totalDone > 0 ? Int(Double(totalCorrect) / Double(totalDone) * 100) : 0
    }
    var totalErrors: Int { totalDone - totalCorrect }

    // MARK: - Загрузка

    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await supabase.auth.user()
            await loadProfile(userId: user.id)
            await loadHistory(userId: user.id)
        } catch {}
    }

    // MARK: - Приватные

    private func loadProfile(userId: UUID) async {
        struct ProfileRow: Decodable {
            let level: String?
            let xp: Int
            let streak_days: Int
            let total_done: Int?
            let total_correct: Int?
        }
        do {
            let rows: [ProfileRow] = try await supabase
                .from("user_profiles")
                .select("level, xp, streak_days, total_done, total_correct")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            if let p = rows.first {
                level = p.level ?? "A1"
                xp = p.xp
                streakDays = p.streak_days
                totalDone = p.total_done ?? 0
                totalCorrect = p.total_correct ?? 0
            }
        } catch {}
    }

    private func loadHistory(userId: UUID) async {
        struct HistRow: Decodable {
            let is_correct: Bool
            let exercise_type: String
            let question: String?
            let correct_answer: String?
            let user_answer: String?
            let created_at: String?
        }
        do {
            let rows: [HistRow] = try await supabase
                .from("exercise_history")
                .select("is_correct, exercise_type, question, correct_answer, user_answer, created_at")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(60)
                .execute()
                .value

            let types = ["multiple_choice", "fill_blank", "translation"]
            typeStats = types.compactMap { t in
                let filtered = rows.filter { $0.exercise_type == t }
                guard !filtered.isEmpty else { return nil }
                return ExerciseTypeStat(
                    type: t,
                    total: filtered.count,
                    correct: filtered.filter { $0.is_correct }.count
                )
            }

            recentHistory = rows.map {
                ExerciseHistoryItem(
                    question: $0.question ?? "—",
                    exerciseType: $0.exercise_type,
                    isCorrect: $0.is_correct,
                    correctAnswer: $0.correct_answer ?? "—",
                    userAnswer: $0.user_answer ?? "—",
                    explanation: "",
                    createdAt: $0.created_at ?? ""
                )
            }
        } catch {}
    }

    // MARK: - Очистка истории по типу

    func clearHistory(exerciseType: String) async {
        do {
            let user = try await supabase.auth.user()
            try await supabase
                .from("exercise_history")
                .delete()
                .eq("user_id", value: user.id.uuidString)
                .eq("exercise_type", value: exerciseType)
                .execute()
        } catch {}
        recentHistory.removeAll { $0.exerciseType == exerciseType }
        typeStats.removeAll { $0.type == exerciseType }
    }

    // MARK: - Порог XP для повышения уровня

    private func levelThreshold(after level: String) -> Int {
        switch level {
        case "A1": return 500
        case "A2": return 1000
        case "B1": return 2000
        case "B2": return 3500
        case "C1": return 5000
        default: return 500
        }
    }
}
