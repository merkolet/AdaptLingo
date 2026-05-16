//
//  HomeViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation
import Combine
internal import Auth
import Supabase

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var level = "A1"
    @Published var displayName = ""
    @Published var xp = 0
    @Published var streakDays = 0
    @Published var totalDone = 0
    @Published var accuracy = 0
    @Published var activeDates: Set<String> = []
    @Published var isLoading = false

    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await supabase.auth.user()
            try await loadProfile(userId: user.id)
            await updateStreakIfNeeded(userId: user.id)
            await loadExerciseStats(userId: user.id)
            await loadActiveDates(userId: user.id)
        } catch {}
    }

    // MARK: - Приватные методы

    private func loadProfile(userId: UUID) async throws {
        struct ProfileRow: Decodable {
            let level: String?
            let xp: Int
            let streak_days: Int
            let display_name: String?
        }
        let rows: [ProfileRow] = try await supabase
            .from("user_profiles")
            .select("level, xp, streak_days, display_name")
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        if let p = rows.first {
            level = p.level ?? "A1"
            xp = p.xp
            streakDays = p.streak_days
            displayName = p.display_name ?? ""
        }
    }

    private func loadActiveDates(userId: UUID) async {
        struct Row: Decodable { let created_at: String }
        do {
            let rows: [Row] = try await supabase
                .from("exercise_history")
                .select("created_at")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dayFmt = DateFormatter()
            dayFmt.dateFormat = "yyyy-MM-dd"
            activeDates = Set(rows.compactMap { row in
                (iso.date(from: row.created_at)).map { dayFmt.string(from: $0) }
            })
        } catch {}
    }

    private func loadExerciseStats(userId: UUID) async {
        struct HistRow: Decodable { let is_correct: Bool }
        do {
            let rows: [HistRow] = try await supabase
                .from("exercise_history")
                .select("is_correct")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            totalDone = rows.count
            let correct = rows.filter { $0.is_correct }.count
            accuracy = totalDone > 0 ? Int(Double(correct) / Double(totalDone) * 100) : 0
        } catch {}
    }

    // MARK: - Обновление стрика

    private func updateStreakIfNeeded(userId: UUID) async {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let todayStr = fmt.string(from: Date())

        struct ActivityRow: Decodable {
            let streak_days:   Int
            let last_activity: String?
        }
        do {
            let rows: [ActivityRow] = try await supabase
                .from("user_profiles")
                .select("streak_days, last_activity")
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            guard let row = rows.first else { return }

            if row.last_activity == todayStr { return }

            var newStreak: Int
            if let lastStr = row.last_activity,
               let lastDate = fmt.date(from: lastStr) {
                let calendar = Calendar.current
                let diff = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: lastDate),
                    to:   calendar.startOfDay(for: Date())
                ).day ?? 0

                newStreak = diff == 1 ? row.streak_days + 1 : 1
            } else {
                newStreak = 1
            }

            struct ActivityUpdate: Encodable {
                let streak_days:   Int
                let last_activity: String
            }
            try await supabase
                .from("user_profiles")
                .update(ActivityUpdate(streak_days: newStreak, last_activity: todayStr))
                .eq("id", value: userId.uuidString)
                .execute()

            streakDays = newStreak
        } catch {}
    }
}
