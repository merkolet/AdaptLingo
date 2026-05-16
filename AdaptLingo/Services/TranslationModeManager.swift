//
//  TranslationModeManager.swift
//  AdaptLingo
//

import Combine
import Foundation

enum TranslationMode: String {
    case llm = "llm"
    case coreML = "coreml"

    var displayName: String {
        switch self {
        case .llm: return "Удалённая нейросеть"
        case .coreML: return "Локальная модель (CoreML)"
        }
    }
}

final class TranslationModeManager: ObservableObject {
    static let shared = TranslationModeManager()
    private static let key = "translation_mode"

    @Published var mode: TranslationMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.key) }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? "llm"
        mode = TranslationMode(rawValue: raw) ?? .llm
    }
}
