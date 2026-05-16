//
//  LLMParsingTests.swift
//  AdaptLingoTests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest
@testable import AdaptLingo

final class LLMParsingTests: XCTestCase {

    // MARK: - Вспомогательный метод

    private func parse(_ json: String, fallback: String = "multiple_choice") throws -> [LLMExercise] {
        let service = LLMService.shared
        return try parseExercisesTestable(from: json, fallbackType: fallback)
    }

    /// Тестируемая копия логики parseExercises из LLMService
    private func parseExercisesTestable(from text: String, fallbackType: String) throws -> [LLMExercise] {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")

        guard let start = cleaned.firstIndex(of: "["),
              let end   = cleaned.lastIndex(of: "]") else {
            throw LLMParsingError.noArray
        }
        let jsonSlice = String(cleaned[start...end])
        guard let data = jsonSlice.data(using: .utf8) else { throw LLMParsingError.noData }

        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LLMParsingError.badStructure
        }

        let trailingPunct = CharacterSet(charactersIn: ".!?,;:")
        func normalize(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines)
             .trimmingCharacters(in: trailingPunct)
             .replacingOccurrences(of: "\u{2019}", with: "'")
             .replacingOccurrences(of: "\u{2018}", with: "'")
             .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
             .lowercased()
        }

        return rawArray.compactMap { dict -> LLMExercise? in
            let type  = (dict["type"] as? String) ?? fallbackType
            guard let quest = dict["question"] as? String, !quest.isEmpty else { return nil }

            let options: [String]
            if let arr = dict["options"] as? [String] {
                options = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if let arr = dict["options"] as? [Any] {
                options = arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else { return nil }
            guard options.count == 4 else { return nil }

            let rawAnswer = ((dict["answer"] as? String) ?? (dict["correct_answer"] as? String) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !rawAnswer.isEmpty else { return nil }

            let normalizedAnswer = normalize(rawAnswer)
            guard let matchedOption = options.first(where: { normalize($0) == normalizedAnswer }) else { return nil }

            return LLMExercise(
                type: type, difficulty: dict["difficulty"] as? String,
                instruction: "", question: quest, options: options,
                answer: matchedOption, explanation: (dict["explanation"] as? String) ?? ""
            )
        }
    }

    enum LLMParsingError: Error { case noArray, noData, badStructure }

    // MARK: - Тест 1: корректный JSON

    func testParseValidJSON() throws {
        let json = """
        [
          {"type":"multiple_choice","difficulty":"A1","question":"I ___ a student.",
           "options":["is","are","am","be"],"answer":"am","explanation":"Используем am."}
        ]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].answer, "am")
        XCTAssertEqual(result[0].question, "I ___ a student.")
    }

    // MARK: - Тест 2: JSON обёрнут в markdown-блок

    func testParseMarkdownWrappedJSON() throws {
        let json = """
        ```json
        [{"type":"fill_blank","question":"She ___ to school.","options":["go","goes","going","gone"],"answer":"goes","explanation":"3-е лицо."}]
        ```
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].answer, "goes")
    }

    // MARK: - Тест 3: поле type отсутствует → fallback

    func testMissingTypeFieldUsesFallback() throws {
        let json = """
        [{"question":"How are you?","options":["Fine","Bad","Who","Where"],"answer":"Fine","explanation":"Ответ."}]
        """
        let result = try parse(json, fallback: "translation")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].type, "translation")
    }

    // MARK: - Тест 4: fuzzy matching — ответ с точкой на конце

    func testFuzzyAnswerMatchWithTrailingPeriod() throws {
        let json = """
        [{"type":"translation","question":"Как дела?",
          "options":["Fine, thanks.","Who are you?","Where are you?","How old are you?"],
          "answer":"Fine, thanks.","explanation":"Ответ."}]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].answer, "Fine, thanks.")
    }

    // MARK: - Тест 5: ответ не совпадает ни с одним вариантом → отфильтровывается

    func testAnswerNotInOptionsFiltersOut() throws {
        let json = """
        [{"type":"multiple_choice","question":"I ___ happy.",
          "options":["is","are","am","be"],"answer":"was","explanation":"—"}]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Тест 6: менее 4 вариантов → отфильтровывается

    func testFewerThan4OptionsFiltersOut() throws {
        let json = """
        [{"type":"multiple_choice","question":"I ___ happy.",
          "options":["is","are","am"],"answer":"am","explanation":"—"}]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Тест 7: несколько упражнений, часть невалидна

    func testMixedValidAndInvalid() throws {
        let json = """
        [
          {"type":"multiple_choice","question":"I ___ a student.",
           "options":["is","are","am","be"],"answer":"am","explanation":"OK"},
          {"type":"multiple_choice","question":"",
           "options":["is","are","am","be"],"answer":"am","explanation":"Пустой вопрос"},
          {"type":"fill_blank","question":"She ___ happy.",
           "options":["is","are","am","be"],"answer":"is","explanation":"OK"}
        ]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Тест 8: JSON с дополнительным текстом до и после массива

    func testJSONWithSurroundingText() throws {
        let json = """
        Here are your exercises:
        [{"type":"multiple_choice","question":"She ___ happy.","options":["is","are","am","be"],"answer":"is","explanation":"3 лицо."}]
        That's all!
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Тест 9: поле correct_answer вместо answer

    func testCorrectAnswerFieldAlias() throws {
        let json = """
        [{"type":"multiple_choice","question":"I ___ happy.",
          "options":["is","are","am","be"],"correct_answer":"am","explanation":"OK"}]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].answer, "am")
    }

    // MARK: - Тест 10: русский текст в вопросе для non-translation → отфильтровывается

    func testCyrillicInNonTranslationFiltersOut() throws {
        let json = """
        [{"type":"fill_blank","question":"Вставь слово в предложение ___.",
          "options":["go","goes","gone","going"],"answer":"goes","explanation":"—"}]
        """
        let result = try parse(json)
        XCTAssertEqual(result.count, 0)
    }
}
