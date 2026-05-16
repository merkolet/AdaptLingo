//
//  Exercise.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation

struct Exercise: Identifiable {
    let id = UUID()
    let type: ExerciseType
    let difficulty: String        // "A1" | "A2" | "B1" | "B2" | "C1"
    let instruction: String
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String

    var userAnswer: String? = nil
    var isCorrect: Bool? = nil

    // MARK: - Тип упражнения

    enum ExerciseType: String, CaseIterable {
        case fillBlank = "fill_blank"
        case multipleChoice = "multiple_choice"
        case translation = "translation"

        var displayName: String {
            switch self {
            case .fillBlank: return "Заполни пропуск"
            case .multipleChoice: return "Выбор варианта"
            case .translation: return "Перевод"
            }
        }

        var icon: String {
            switch self {
            case .fillBlank: return "pencil.line"
            case .multipleChoice: return "checkmark.circle"
            case .translation: return "arrow.left.arrow.right"
            }
        }
    }

    // MARK: - Фабричный метод

    static func from(_ llm: LLMExercise) -> Exercise {
        Exercise(
            type: ExerciseType(rawValue: llm.type) ?? .multipleChoice,
            difficulty: llm.difficulty ?? "A1",
            instruction: llm.instruction,
            question: llm.question,
            options: llm.options,
            correctAnswer: llm.answer,
            explanation: llm.explanation
        )
    }
}

// MARK: - Состояние кнопки варианта ответа

enum ExerciseOptionState {
    case normal
    case correct
    case wrong
}
