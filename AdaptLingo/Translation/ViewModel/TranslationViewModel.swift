//
//  TranslationViewModel.swift
//  AdaptLingo
//

import Foundation
import Combine

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var resultText = ""
    @Published var isFromRussian = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOfflineFallback = false

    var sourceLang: String { isFromRussian ? "Русский" : "Английский" }
    var targetLang: String { isFromRussian ? "Английский" : "Русский"   }

    private let modeManager = TranslationModeManager.shared
    private let networkMonitor = NetworkMonitor.shared

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        Task {
            isLoading = true
            errorMessage = nil
            resultText = ""
            isOfflineFallback = false

            let src = isFromRussian ? "Russian" : "English"
            let dst = isFromRussian ? "English" : "Russian"

            do {
                if modeManager.mode == .coreML {
                    resultText = try await NLLBTranslationService.shared.translate(text, from: src, to: dst)

                } else if !networkMonitor.isConnected {
                    isOfflineFallback = true
                    resultText = try await NLLBTranslationService.shared.translate(text, from: src, to: dst)

                } else {
                    do {
                        resultText = try await LLMService.shared.translateText(text, from: src, to: dst)
                    } catch {
                        if isConnectivityError(error) {
                            isOfflineFallback = true
                            resultText = try await NLLBTranslationService.shared.translate(text, from: src, to: dst)
                        } else {
                            throw error
                        }
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func swapLanguages() {
        isFromRussian.toggle()
        if !resultText.isEmpty {
            let tmp = inputText
            inputText = resultText
            resultText = tmp
        }
    }

    func clear() {
        inputText = ""
        resultText = ""
        errorMessage = nil
        isOfflineFallback = false
    }

    // MARK: - Приватные

    private func isConnectivityError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return [.notConnectedToInternet, .networkConnectionLost, .timedOut]
                .contains(urlError.code)
        }
        if case LLMError.networkError(let msg) = error {
            let lower = msg.lowercased()
            return lower.contains("offline") || lower.contains("internet") || lower.contains("connection")
        }
        return false
    }
}
