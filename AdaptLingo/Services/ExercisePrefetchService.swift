//
//  ExercisePrefetchService.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//
//  Запускает генерацию всех 3 типов упражнений параллельно, как только
//  пользователь открывает экран уроков. К моменту тапа на карточку
//  упражнения чаще всего уже готовы.
//

import Foundation

@MainActor
final class ExercisePrefetchService {
    static let shared = ExercisePrefetchService()
    private init() {}

    private var tasks: [String: Task<[Exercise]?, Never>] = [:]

    // MARK: - API

    func prefetchAll(level: String) {
        for type in Exercise.ExerciseType.allCases {
            let key = type.rawValue
            guard tasks[key] == nil else { continue }
            tasks[key] = Task {
                do {
                    let raw = try await LLMService.shared.generateExercises(
                        level: level,
                        exerciseType: key
                    )
                    return raw.map { Exercise.from($0) }
                } catch {
                    return nil
                }
            }
        }
    }

    func dequeue(type: Exercise.ExerciseType) async -> [Exercise]? {
        let key = type.rawValue
        guard let task = tasks.removeValue(forKey: key) else { return nil }
        return await task.value
    }

    func invalidate() {
        tasks.values.forEach { $0.cancel() }
        tasks = [:]
    }
}
