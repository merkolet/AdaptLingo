//
//  ExerciseSessionViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation
import Combine
internal import Auth
import Supabase

@MainActor
final class ExerciseSessionViewModel: ObservableObject {

    // MARK: - Состояние

    @Published var exercises: [Exercise] = []
    @Published var currentIndex = 0
    @Published var selectedAnswer: String? = nil
    @Published var isAnswerRevealed = false
    @Published var isLoading = true
    @Published var loadError: String? = nil
    @Published var sessionComplete = false
    @Published var score = 0

    let exerciseType: Exercise.ExerciseType

    // MARK: - Init

    init(exerciseType: Exercise.ExerciseType) {
        self.exerciseType = exerciseType
    }

    // MARK: - Вычисляемые свойства

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var isLastQuestion: Bool {
        exercises.isEmpty ? false : currentIndex == exercises.count - 1
    }

    var progress: Double {
        exercises.isEmpty ? 0 : Double(currentIndex) / Double(exercises.count)
    }

    var xpEarned: Int { score * 10 }

    var wrongExercises: [Exercise] {
        exercises.filter { $0.isCorrect == false }
    }

    // MARK: - Действия

    func loadExercises() async {
        isLoading = true
        loadError = nil

        let level = await getUserLevel()

        do {
            if let cached = await ExercisePrefetchService.shared.dequeue(type: exerciseType) {
                exercises = cached
            } else {
                let raw = try await LLMService.shared.generateExercises(
                    level       : level,
                    exerciseType: exerciseType.rawValue
                )
                exercises = raw.map { Exercise.from($0) }
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    func selectAnswer(_ answer: String) {
        guard !isAnswerRevealed, currentExercise != nil else { return }

        selectedAnswer = answer
        let isCorrect = answer == exercises[currentIndex].correctAnswer

        exercises[currentIndex].userAnswer = answer
        exercises[currentIndex].isCorrect  = isCorrect

        if isCorrect { score += 1 }

        isAnswerRevealed = true
    }

    func nextQuestion() {
        if isLastQuestion {
            sessionComplete = true
            Task { await saveSession() }
        } else {
            currentIndex += 1
            selectedAnswer = nil
            isAnswerRevealed = false
        }
    }

    func retry() {
        exercises = []
        currentIndex = 0
        selectedAnswer = nil
        isAnswerRevealed = false
        loadError = nil
        sessionComplete = false
        score = 0
        Task { await loadExercises() }
    }

    func optionState(for option: String) -> ExerciseOptionState {
        guard isAnswerRevealed, let exercise = currentExercise else { return .normal }
        if option == exercise.correctAnswer { return .correct }
        if option == selectedAnswer { return .wrong }
        return .normal
    }

    // MARK: - Приватные методы

    private func getUserLevel() async -> String {
        do {
            let user = try await supabase.auth.user()
            return UserDefaults.standard.string(forKey: "level_\(user.id)") ?? "A1"
        } catch {
            return "A1"
        }
    }

    private func saveSession() async {
        guard !exercises.isEmpty else { return }
        do {
            let user = try await supabase.auth.user()

            struct HistoryRow: Encodable {
                let user_id: UUID
                let exercise_type: String
                let question: String
                let user_answer: String
                let correct_answer: String
                let is_correct: Bool
                let explanation: String
            }

            let rows: [HistoryRow] = exercises.compactMap { ex in
                guard let ua = ex.userAnswer, let ic = ex.isCorrect else { return nil }
                return HistoryRow(
                    user_id: user.id,
                    exercise_type: ex.type.rawValue,
                    question: ex.question,
                    user_answer: ua,
                    correct_answer: ex.correctAnswer,
                    is_correct: ic,
                    explanation: ex.explanation
                )
            }

            if !rows.isEmpty {
                do {
                    try await supabase
                        .from("exercise_history")
                        .insert(rows)
                        .execute()
                } catch {
                    struct HistoryRowBasic: Encodable {
                        let user_id: UUID; let exercise_type: String
                        let question: String; let user_answer: String
                        let correct_answer: String; let is_correct: Bool
                    }
                    let basic: [HistoryRowBasic] = exercises.compactMap { ex in
                        guard let ua = ex.userAnswer, let ic = ex.isCorrect else { return nil }
                        return HistoryRowBasic(
                            user_id: user.id, exercise_type: ex.type.rawValue,
                            question: ex.question, user_answer: ua,
                            correct_answer: ex.correctAnswer, is_correct: ic
                        )
                    }
                    if !basic.isEmpty {
                        try await supabase.from("exercise_history").insert(basic).execute()
                    }
                }
            }

            async let xpTask: () = xpEarned > 0 ? incrementXP(userId: user.id, amount: xpEarned) : ()
            async let statsTask: () = incrementStats(
                userId     : user.id,
                doneDelta  : exercises.count,
                correctDelta: exercises.filter { $0.isCorrect == true }.count
            )
            _ = try? await (xpTask, statsTask)
        } catch {}
    }

    private func incrementXP(userId: UUID, amount: Int) async throws {
        struct XPRow: Decodable { let xp: Int }
        let rows: [XPRow] = try await supabase
            .from("user_profiles")
            .select("xp")
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        let newXP = (rows.first?.xp ?? 0) + amount
        try await supabase
            .from("user_profiles")
            .update(["xp": newXP])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    private func incrementStats(userId: UUID, doneDelta: Int, correctDelta: Int) async throws {
        struct StatsRow: Decodable { let total_done: Int?; let total_correct: Int? }
        let rows: [StatsRow] = try await supabase
            .from("user_profiles")
            .select("total_done, total_correct")
            .eq("id", value: userId.uuidString)
            .execute()
            .value
        let newDone    = (rows.first?.total_done    ?? 0) + doneDelta
        let newCorrect = (rows.first?.total_correct ?? 0) + correctDelta
        try await supabase
            .from("user_profiles")
            .update(["total_done": newDone, "total_correct": newCorrect])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}
