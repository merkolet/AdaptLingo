//
//  LLMService.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import Foundation

// MARK: - Ошибки

enum LLMError: Error, LocalizedError {
    case apiKeyNotSet
    case networkError(String)
    case badStatusCode(Int)
    case emptyResponse
    case parsingError(String)
    case insufficientCredits(available: Int)

    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet: return "API ключ не настроен."
        case .networkError(let msg): return "Ошибка сети: \(msg)"
        case .badStatusCode(let code): return "Ошибка сервера: \(code)"
        case .emptyResponse: return "Пустой ответ от LLM"
        case .parsingError(let msg): return "Ошибка парсинга: \(msg)"
        case .insufficientCredits(let avail): return "Недостаточно кредитов (доступно \(avail) токенов)"
        }
    }
}

// MARK: - Сервис

final class LLMService {
    static let shared = LLMService()
    private init() {}

    private var currentKeyIndex = 0

    // MARK: - Генерация упражнений

    func generateExercises(
        level: String,
        exerciseType: String = "multiple_choice",
        count: Int = 10
    ) async throws -> [LLMExercise] {
        let prompt = makeBatchPrompt(count: count + 7, difficulty: level, exerciseType: exerciseType)
        let text = try await sendMessage(prompt)
        let exercises = try parseExercises(from: text, fallbackType: exerciseType)
        return Array(exercises.prefix(count))
    }

    // MARK: - Базовый запрос с ротацией ключей

    func sendMessage(_ content: String) async throws -> String {
        let models = Config.modelPool
        guard !models.isEmpty else { throw LLMError.apiKeyNotSet }

        for (modelIdx, model) in models.enumerated() {
            do {
                return try await sendMessageWithModel(content, model: model)
            } catch LLMError.networkError(let msg) where msg.contains("исчерпаны") {
                continue
            }
        }
        throw LLMError.networkError("Все модели и ключи исчерпаны")
    }

    private func sendMessageWithModel(_ content: String, model: String) async throws -> String {
        let keys = Config.claudeAPIKeys
        guard !keys.isEmpty else { throw LLMError.apiKeyNotSet }

        for attempt in 0..<keys.count {
            let idx = (currentKeyIndex + attempt) % keys.count
            let key = keys[idx]

            do {
                let result = try await performRequest(key: key, content: content, model: model)
                currentKeyIndex = idx
                return result
            } catch LLMError.badStatusCode(let code) where [401, 402, 429].contains(code) {
                if code == 429 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
                currentKeyIndex = (idx + 1) % keys.count
                continue
            } catch LLMError.insufficientCredits {
                currentKeyIndex = (idx + 1) % keys.count
                continue
            }
        }

        throw LLMError.networkError("Все \(keys.count) API-ключа исчерпаны")
    }

    // MARK: - Приватный HTTP-запрос с конкретным ключом

    private func performRequest(key: String, content: String, model: String) async throws -> String {
        guard let url = URL(string: Config.claudeAPIURL) else {
            throw LLMError.networkError("Неверный URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AdaptLingo", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "messages" : [
                ["role": "system", "content": "You are an English teacher creating exercises for Russian-speaking students. CRITICAL RULE: The 'question' field and all 'options' must ALWAYS be in English. Never write Russian words in 'question' or 'options'. Only 'instruction' and 'explanation' fields may be in Russian."],
                ["role": "user", "content": content]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if http.statusCode == 402,
               let errBody = try? JSONDecoder().decode(OpenRouterErrorBody.self, from: data) {
                let msg = errBody.error.message
              
                if let range = msg.range(of: #"can only afford (\d+)"#, options: .regularExpression) {
                    let digits = msg[range].filter(\.isNumber)
                    if let available = Int(digits) {
                        throw LLMError.insufficientCredits(available: available)
                    }
                }
            }
            throw LLMError.badStatusCode(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
            throw LLMError.emptyResponse
        }
        return text
    }

    // MARK: - Перевод текста

    func translateText(_ text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        let prompt = """
        Translate the following \(sourceLang) text to \(targetLang).
        Return ONLY the translation — no explanations, no quotes, no extra text.

        \(text)
        """
        let result = try await sendMessage(prompt)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Placement Test

    func generatePlacementQuestions(count: Int = 15) async throws -> [PlacementTestQuestion] {
        let prompt = makePlacementPrompt(count: count)
        let text = try await sendMessage(prompt)
        return try parsePlacementQuestions(from: text)
    }

    func evaluatePlacementLevel(
        questions: [PlacementTestQuestion],
        answers: [Int?],
        score: Int
    ) async throws -> (level: String, reason: String) {
        let prompt = makeEvaluationPrompt(questions: questions, answers: answers, score: score)
        let text   = try await sendMessage(prompt)
        return parseLevelFromEvaluation(text)
    }

    // MARK: - Placement Prompt Builders

    private func makePlacementPrompt(count: Int) -> String {
        let perLevel = max(2, count / 5)
        let remainder = count - perLevel * 5
        let a1End  = perLevel
        let a2End  = perLevel * 2
        let b1End  = perLevel * 3 + remainder
        let b2End  = b1End + perLevel
        
        let typeCount = max(2, count / 3)

        return """
        Task: Generate a JSON array of exactly \(count) English placement test questions for Russian learners.

        OUTPUT FORMAT — return ONLY the raw JSON array, nothing else, no markdown, no backticks:
        [
          {"type":"multiple_choice","difficulty":"A1","instruction":"Выбери правильный вариант:","question":"I ___ a student.","options":["is","are","am","be"],"correct_answer":"am"},
          {"type":"fill_blank","difficulty":"A2","instruction":"Вставь пропущенное слово:","question":"She ___ to school every day.","options":["go","goes","going","gone"],"correct_answer":"goes"},
          {"type":"translation","difficulty":"B1","instruction":"Выбери правильный перевод:","question":"Как тебя зовут?","options":["Where are you?","How old are you?","What is your name?","How are you?"],"correct_answer":"What is your name?"}
        ]

        STRICT RULES:
        - "correct_answer" must be EXACTLY one of the 4 "options" strings.
        - Each question must have EXACTLY 4 items in "options".
        - "instruction" must be in Russian.
        - For "fill_blank": ___ (three underscores) must appear in "question".
        - For "translation": "question" is Russian; all 4 options are English translations.
        - For "multiple_choice" and "fill_blank": "question" must be in ENGLISH only.

        DIFFICULTY — strictly in this order:
        - Items 1-\(a1End): "A1" — verb to be, greetings, numbers, colors, Present Simple basics
        - Items \(a1End+1)-\(a2End): "A2" — Past Simple, articles, Present Continuous, common phrases
        - Items \(a2End+1)-\(b1End): "B1" — Present Perfect, Future forms, conditionals, phrasal verbs
        - Items \(b1End+1)-\(b2End): "B2" — passive voice, reported speech, complex tenses, advanced vocabulary, idioms
        - Items \(b2End+1)-\(count): "C1" — nuanced grammar, formal/informal register, collocations, complex structures, sophisticated idioms

        TYPE COUNT (distribute evenly across all difficulty groups):
        - \(typeCount) × "multiple_choice"
        - \(typeCount) × "fill_blank"
        - \(count - typeCount * 2) × "translation"

        Now output the JSON array of exactly \(count) questions:
        """
    }

    private func makeEvaluationPrompt(
        questions: [PlacementTestQuestion],
        answers: [Int?],
        score: Int
    ) -> String {
        var lines: [String] = [
            "Placement test results for an English learner (Russian speaker). Analyze and assign a CEFR level.\n"
        ]
        for (i, q) in questions.enumerated() {
            let userIdx = answers.indices.contains(i) ? answers[i] : nil
            let userAnswer = userIdx.flatMap { $0 < q.options.count ? q.options[$0] : nil } ?? "—"
            let correct = userAnswer == q.correctAnswer
            lines.append("\(i + 1). [\(q.difficulty) | \(q.type.rawValue)] \(q.questionText)")
            lines.append("Correct: \"\(q.correctAnswer)\"  User: \"\(userAnswer)\" \(correct ? "✓" : "✗")")
        }
        lines.append("\nTotal score: \(score) / \(questions.count)")
        lines.append("""

        Instructions:
        - Analyze WHICH questions were correct/incorrect, not just the total score.
        - A learner who fails A1 questions is A1; one who handles A2 but struggles at B1 is A2, etc.
        - Possible levels: A1, A2, B1, B2, C1.
        - Write a brief reason in RUSSIAN (1-2 sentences).

        Return ONLY valid JSON (no markdown, no code blocks):
        {"level":"B1","reason":"Вы уверенно справились с базовыми и элементарными вопросами, но допустили ошибки в заданиях среднего уровня."}
        """)
        return lines.joined(separator: "\n")
    }

    // MARK: - Placement Parsers

    private func parsePlacementQuestions(from text: String) throws -> [PlacementTestQuestion] {

        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")

        guard let startIdx = cleaned.firstIndex(of: "["),
              let endIdx   = cleaned.lastIndex(of: "]") else {
            throw LLMError.parsingError("JSON-массив не найден в ответе")
        }
        let jsonSlice = String(cleaned[startIdx...endIdx])
        guard let data = jsonSlice.data(using: .utf8) else {
            throw LLMError.parsingError("Не удалось конвертировать JSON в Data")
        }

        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LLMError.parsingError("Неверная структура JSON-массива")
        }

        let questions = rawArray.compactMap { dict -> PlacementTestQuestion? in
            guard let typeStr = dict["type"] as? String,
                  let qType  = PlacementTestQuestion.QuestionType(rawValue: typeStr)
            else { return nil }

            guard let questionText = dict["question"] as? String,
                  !questionText.isEmpty
            else { return nil }

            let options: [String]
            if let arr = dict["options"] as? [String] {
                options = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if let arr = dict["options"] as? [Any] {
                options = arr.compactMap { ($0 as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) }
            } else {
                return nil
            }
            guard options.count == 4 else { return nil }

            let correctAnswer = ((dict["correct_answer"] as? String)
                ?? (dict["correctAnswer"] as? String)
                ?? (dict["answer"] as? String)
                ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !correctAnswer.isEmpty, options.contains(correctAnswer) else { return nil }

            let difficulty = (dict["difficulty"] as? String) ?? "A1"
            let instruction = (dict["instruction"] as? String) ?? defaultInstruction(for: typeStr)

            return PlacementTestQuestion(
                type: qType,
                difficulty: difficulty,
                instruction: instruction,
                questionText: questionText,
                options: options,
                correctAnswer: correctAnswer
            )
        }

        guard questions.count >= 5 else {
            throw LLMError.parsingError(
                "Мало корректных вопросов: \(questions.count) из \(rawArray.count)"
            )
        }
        return questions
    }

    private func defaultInstruction(for type: String) -> String {
        switch type {
        case "fill_blank": return "Вставь пропущенное слово:"
        case "translation": return "Выбери правильный перевод:"
        default: return "Выбери правильный вариант:"
        }
    }

    private func parseLevelFromEvaluation(_ text: String) -> (level: String, reason: String) {
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}"),
           let data = String(text[start...end]).data(using: .utf8),
           let eval = try? JSONDecoder().decode(LevelEvaluation.self, from: data) {
            return (eval.level, eval.reason)
        }
        for level in ["C1", "B2", "B1", "A2", "A1"] {
            if text.contains(level) { return (level, "") }
        }
        return ("A1", "")
    }

    // MARK: - Приватные методы

    private static let topics = [
        "everyday life", "travel & transport", "work & career", "food & cooking",
        "sports & fitness", "technology & internet", "nature & environment",
        "culture & arts", "health & medicine", "education & learning",
        "shopping & money", "family & relationships", "weather & seasons",
        "music & films", "cities & countries"
    ]

    private func makeBatchPrompt(count: Int, difficulty: String, exerciseType: String) -> String {
        let typeRule = exerciseTypeRule(exerciseType)
        let topic    = Self.topics.randomElement() ?? "everyday life"
        return """
        You are an English teacher. Generate exactly \(count) ENGLISH exercises at difficulty level "\(difficulty)" for a Russian-speaking student.

        TOPIC FOCUS: "\(topic)" — use vocabulary and situations related to this topic. Do NOT repeat exercises from previous sessions.

        LANGUAGE — CRITICAL:
        - "question" must be in ENGLISH
        - "options" must be in ENGLISH
        - "instruction" in Russian
        - "explanation" in Russian (2-4 sentences): explain WHY the correct answer is right, name the grammar rule, and briefly say why the wrong options are incorrect
        - ONLY "translation" type: question is Russian, options are English

        OUTPUT: return ONLY raw JSON array, no markdown, no backticks:
        \(outputExample(exerciseType, difficulty))

        TYPE: All \(count) must be "\(exerciseType)". Level: \(difficulty) — \(levelGuidance(difficulty)).
        \(typeRule)

        STRICT: answer must exactly match one option. 4 options each. No Russian in question/options (except translation).
        Output JSON array of exactly \(count) exercises:
        """
    }

    private func outputExample(_ type: String, _ difficulty: String) -> String {
        switch type {
        case "fill_blank":
            return """
            [{"type":"fill_blank","difficulty":"\(difficulty)","question":"She ___ to school every day.","options":["go","goes","going","gone"],"answer":"goes","explanation":"В Present Simple с подлежащим she/he/it глагол получает окончание -s. Поэтому правильно goes, а не go (форма для I/you/we/they). Going и gone — это причастие и причастие II, они не используются здесь без вспомогательного глагола."}]
            """
        case "translation":
            return """
            [{"type":"translation","difficulty":"\(difficulty)","question":"Как дела?","options":["Who are you?","How are you?","Where are you?","What time is it?"],"answer":"How are you?","explanation":"How are you? дословно означает «Как ты?» и используется как стандартное приветствие. Who are you? — «Кто ты?», Where are you? — «Где ты?», What time is it? — «Который час?» — все они переводятся совсем иначе."}]
            """
        default:
            return """
            [{"type":"multiple_choice","difficulty":"\(difficulty)","question":"Which sentence uses the Present Perfect correctly?","options":["I have seen him yesterday.","I saw him yesterday.","I have seen him last week.","I seen him already."],"answer":"I saw him yesterday.","explanation":"Present Perfect нельзя использовать с конкретными временными маркерами прошлого (yesterday, last week) — для них нужен Past Simple. I saw him yesterday — правильно (Past Simple). I have seen him yesterday/last week — ошибочны. I seen him already — неверно, пропущен вспомогательный глагол have."}]
            """
        }
    }

    private func exerciseTypeRule(_ type: String) -> String {
        switch type {
        case "fill_blank":
            return """
            fill_blank RULES:
            - Sentence MUST contain exactly ___ (three underscores) as a blank to fill.
            - Options are single words or short phrases that fit the blank.
            - NEVER write a complete question — always an incomplete sentence with ___.
            Example: {"question":"She ___ to school every day.","options":["go","goes","going","gone"],"answer":"goes"}
            Example: {"question":"I have ___ apple and ___ banana.","options":["a / a","an / a","a / an","an / an"],"answer":"an / a"}
            """
        case "translation":
            return """
            translation RULES:
            - "question" = a Russian phrase or sentence (Cyrillic only).
            - "options" = 4 different English translations (complete sentences or phrases).
            - NEVER use ___ in question or options.
            Example: {"question":"Как дела?","options":["Who are you?","How are you?","Where are you?","What time is it?"],"answer":"How are you?"}
            Example: {"question":"Мне нравится читать.","options":["I like to read.","I liked reading.","I want to read.","I read a lot."],"answer":"I like to read."}
            """
        default:
            return """
            multiple_choice RULES:
            - NEVER use ___ (blanks). The question must be COMPLETE — no missing words.
            - Ask about grammar rules, vocabulary meaning, correct/incorrect sentences, or word choice.
            - Options are complete words, phrases, or full sentences — NOT fillers for a blank.
            - Question formats to use:
              • "Which sentence is grammatically correct?"
              • "What is the past tense of [verb]?"
              • "Which word means [meaning]?"
              • "Choose the correct form: [context]"
              • "Which tense is used for [situation]?"
            Example: {"question":"Which sentence is grammatically correct?","options":["She don't like coffee.","She doesn't like coffee.","She not like coffee.","She isn't like coffee."],"answer":"She doesn't like coffee."}
            Example: {"question":"What is the past tense of 'buy'?","options":["buyed","boughted","bought","buys"],"answer":"bought"}
            Example: {"question":"Which word means the opposite of 'ancient'?","options":["old","historic","modern","antique"],"answer":"modern"}
            """
        }
    }

    private func levelGuidance(_ level: String) -> String {
        switch level {
        case "A1": return "very basic: verb to be, greetings, numbers, colors, Present Simple"
        case "A2": return "elementary: Past Simple, articles, common phrases, Present Continuous"
        case "B1": return "intermediate: Present Perfect, Future, conditionals, phrasal verbs"
        case "B2": return "upper-intermediate: passive voice, complex tenses, idioms, advanced vocab"
        case "C1": return "advanced: nuanced grammar, formal/informal register, complex structures"
        default: return "basic: verb to be, Present Simple"
        }
    }

    private func nextLevel(_ level: String) -> String {
        switch level {
        case "A1": return "A2"
        case "A2": return "B1"
        case "B1": return "B2"
        case "B2": return "C1"
        default: return "C1"
        }
    }

    private func parseExercises(from text: String, fallbackType: String = "multiple_choice") throws -> [LLMExercise] {

        let cleaned = text
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")

        guard let start = cleaned.firstIndex(of: "["),
              let end   = cleaned.lastIndex(of: "]") else {
            throw LLMError.parsingError("JSON-массив не найден в ответе")
        }
        let jsonSlice = String(cleaned[start...end])
        guard let data = jsonSlice.data(using: .utf8) else {
            throw LLMError.parsingError("Не удалось конвертировать JSON")
        }

        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LLMError.parsingError("Неверная структура JSON")
        }

        let exercises: [LLMExercise] = rawArray.compactMap { dict in
            let type  = (dict["type"] as? String) ?? fallbackType
            guard let quest = dict["question"] as? String,
                  !quest.isEmpty else { return nil }

            let options: [String]
            if let arr = dict["options"] as? [String] {
                options = arr.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else if let arr = dict["options"] as? [Any] {
                options = arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            } else { return nil }
            guard options.count == 4 else { return nil }

            let rawAnswer = ((dict["answer"] as? String)
                ?? (dict["correct_answer"] as? String)
                ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !rawAnswer.isEmpty else { return nil }

            let trailingPunct = CharacterSet(charactersIn: ".!?,;:")
            func normalize(_ s: String) -> String {
                s.trimmingCharacters(in: .whitespacesAndNewlines)
                 .trimmingCharacters(in: trailingPunct)
                 .replacingOccurrences(of: "\u{2019}", with: "'")
                 .replacingOccurrences(of: "\u{2018}", with: "'")
                 .replacingOccurrences(of: "\u{201C}", with: "\"")
                 .replacingOccurrences(of: "\u{201D}", with: "\"")
                 .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
                 .lowercased()
            }
            let normalizedAnswer = normalize(rawAnswer)
            guard let matchedOption = options.first(where: { normalize($0) == normalizedAnswer }) else {
                return nil
            }

            if type != "translation" && quest.unicodeScalars.contains(where: { CharacterSet.cyrillics.contains($0) }) {
                return nil
            }

            return LLMExercise(
                type: type,
                difficulty: dict["difficulty"] as? String,
                instruction: defaultInstructionForType(type),
                question: quest,
                options: options,
                answer: matchedOption,
                explanation: (dict["explanation"] as? String) ?? ""
            )
        }

        guard exercises.count >= 3 else {
            throw LLMError.parsingError("Мало валидных упражнений: \(exercises.count)/\(rawArray.count)")
        }
        return exercises
    }

    private func defaultInstructionForType(_ type: String) -> String {
        switch type {
        case "fill_blank": return "Вставь пропущенное слово:"
        case "translation": return "Выбери правильный перевод:"
        default: return "Выбери правильный вариант:"
        }
    }
}

// MARK: - Вспомогательные модели (внутренние для LLM-слоя)

private struct OpenRouterErrorBody: Decodable {
    let error: OpenRouterError
    struct OpenRouterError: Decodable {
        let message: String
        let code: Int?
    }
}

struct OpenAIResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: Message
    }
    struct Message: Decodable {
        let content: String
    }
}

struct LLMExercise: Decodable {
    let type: String
    let difficulty: String?
    let instruction: String
    let question: String
    let options: [String]
    let answer: String
    let explanation: String
}

private extension CharacterSet {
    static let cyrillics = CharacterSet(charactersIn: "\u{0400}"..."\u{04FF}")
}
