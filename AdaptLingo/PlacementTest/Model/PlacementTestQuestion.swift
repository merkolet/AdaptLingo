//
//  PlacementTestQuestion.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation

// MARK: - Тип вопроса

extension PlacementTestQuestion {
    enum QuestionType: String {
        case multipleChoice = "multiple_choice"
        case fillBlank = "fill_blank"
        case translation = "translation"

        var displayName: String {
            switch self {
            case .multipleChoice: return "Выбор варианта"
            case .fillBlank: return "Заполни пропуск"
            case .translation: return "Перевод"
            }
        }

        var icon: String {
            switch self {
            case .multipleChoice: return "checkmark.circle"
            case .fillBlank: return "pencil.line"
            case .translation: return "arrow.left.arrow.right"
            }
        }
    }

    enum QuestionCategory {
        case vocabulary, grammar, phrases

        var displayName: String {
            switch self {
            case .vocabulary: return "Лексика"
            case .grammar: return "Грамматика"
            case .phrases: return "Фразы"
            }
        }

        var icon: String {
            switch self {
            case .vocabulary: return "textformat.abc"
            case .grammar: return "pencil"
            case .phrases: return "quote.bubble"
            }
        }
    }
}

// MARK: - Модель вопроса

struct PlacementTestQuestion: Identifiable {
    let id = UUID()
    let type: QuestionType
    let difficulty: String
    let instruction: String
    let questionText: String
    let options: [String]
    let correctAnswer: String

    var correctAnswerIndex: Int {
        options.firstIndex(of: correctAnswer) ?? 0
    }

    var category: QuestionCategory {
        switch type {
        case .multipleChoice: return .grammar
        case .fillBlank: return .grammar
        case .translation: return .phrases
        }
    }
}

// MARK: - Состояние кнопки ответа

enum AnswerButtonState {
    case normal
    case selected
}

// MARK: - LLM JSON-бридж

struct LLMPlacementQuestion: Decodable {
    let type: String
    let difficulty: String
    let instruction: String
    let question: String
    let options: [String]
    let correct_answer: String

    func toQuestion() -> PlacementTestQuestion? {
        guard let qType = PlacementTestQuestion.QuestionType(rawValue: type),
              options.count == 4,
              options.contains(correct_answer)
        else { return nil }

        return PlacementTestQuestion(
            type: qType,
            difficulty: difficulty,
            instruction: instruction,
            questionText: question,
            options: options,
            correctAnswer: correct_answer
        )
    }
}

// MARK: - Ответ LLM на оценку уровня

struct LevelEvaluation: Decodable {
    let level : String
    let reason: String
}
