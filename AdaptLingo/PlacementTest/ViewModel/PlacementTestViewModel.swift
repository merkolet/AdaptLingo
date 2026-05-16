//
//  PlacementTestViewModel.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation
import Supabase
import Combine

@MainActor
final class PlacementTestViewModel: ObservableObject {

    // MARK: - Вопросы

    @Published private(set) var questions: [PlacementTestQuestion] = []
    @Published var currentIndex = 0
    @Published var selectedAnswerIndex: Int? = nil

    // MARK: - Результат

    @Published var score = 0
    @Published var isCompleted = false
    @Published var assignedLevel = "A1"
    @Published var levelReason = ""
    @Published var isSaving = false

    // MARK: - Состояния загрузки

    @Published var isLoadingQuestions = false
    @Published var loadingError: String? = nil
    @Published var isEvaluating = false

    // MARK: - Приватные данные

    private var userAnswers: [Int?] = []

    // MARK: - Init

    init() {
        Task { await loadQuestions() }
    }

    // MARK: - Вычисляемые свойства

    var currentQuestion: PlacementTestQuestion {
        questions[currentIndex]
    }

    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

    var progress: Double {
        questions.isEmpty ? 0 : Double(currentIndex + 1) / Double(questions.count)
    }

    func answerState(for index: Int) -> AnswerButtonState {
        selectedAnswerIndex == index ? .selected : .normal
    }

    // MARK: - Действия

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    /// Переход к следующему вопросу или запуск оценки уровня
    func nextQuestion() {
        guard let selected = selectedAnswerIndex else { return }

        if currentIndex < userAnswers.count {
            userAnswers[currentIndex] = selected
        }

        if selected == currentQuestion.correctAnswerIndex {
            score += 1
        }

        if isLastQuestion {
            isEvaluating = true
            Task { await evaluateLevel() }
        } else {
            currentIndex += 1
            selectedAnswerIndex = nil
        }
    }

    // MARK: - Загрузка вопросов

    func loadQuestions() async {
        isLoadingQuestions = true
        loadingError = nil
        currentIndex = 0
        score = 0
        selectedAnswerIndex = nil
        isCompleted = false

        do {
            questions = try await LLMService.shared.generatePlacementQuestions()
            userAnswers = Array(repeating: nil, count: questions.count)
        } catch {
            loadingError = error.localizedDescription
        }
        isLoadingQuestions = false
    }

    // MARK: - Оценка уровня через LLM

    private func evaluateLevel() async {
        do {
            let result = try await LLMService.shared.evaluatePlacementLevel(
                questions: questions,
                answers  : userAnswers,
                score    : score
            )
            assignedLevel = result.level
            levelReason   = result.reason
        } catch {
            assignedLevel = scoreBasedLevel(score: score, total: questions.count)
            levelReason   = ""
        }
        isEvaluating = false
        isCompleted   = true

        ExercisePrefetchService.shared.prefetchAll(level: assignedLevel)
    }

    private func scoreBasedLevel(score: Int, total: Int) -> String {
        let pct = total > 0 ? Double(score) / Double(total) : 0
        switch pct {
        case 0.93...: return "C1"
        case 0.73...: return "B2"
        case 0.53...: return "B1"
        case 0.33...: return "A2"
        default: return "A1"
        }
    }

    // MARK: - Сохранение результата

    func saveResult() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let user = try await supabase.auth.user()
            UserDefaults.standard.set(true, forKey: "placement_done_\(user.id)")
            UserDefaults.standard.set(assignedLevel, forKey: "level_\(user.id)")
            try? await saveToSupabase(userId: user.id)
        } catch {}
    }

    // MARK: - Приватные хелперы

    private func saveToSupabase(userId: UUID) async throws {
        struct ProfileInsert: Encodable {
            let id: UUID; let language: String; let level: String; let xp: Int
        }
        try await supabase
            .from("user_profiles")
            .upsert(ProfileInsert(id: userId, language: "en", level: assignedLevel, xp: 0))
            .execute()

        struct PlacementResult: Encodable {
            let user_id: UUID
            let assigned_level: String
            let score: Int
            let total: Int
            let accuracy_pct: Int
            let reason: String
        }
        let accuracy = questions.isEmpty ? 0 : Int(Double(score) / Double(questions.count) * 100)
        try await supabase
            .from("placement_results")
            .insert(PlacementResult(
                user_id: userId,
                assigned_level: assignedLevel,
                score: score,
                total: questions.count,
                accuracy_pct: accuracy,
                reason: levelReason
            ))
            .execute()
    }
}
