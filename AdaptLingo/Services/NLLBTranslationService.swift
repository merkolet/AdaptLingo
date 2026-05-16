//
//  NLLBTranslationService.swift
//  AdaptLingo
//
//  Created by Sergey on 23.04.2026.
//

import Foundation
import CoreML
import Accelerate
import SentencepieceTokenizer

// MARK: - Ошибки

enum NLLBError: Error, LocalizedError {
    case modelLoadFailed
    case tokenizationFailed
    case encodingFailed
    case decodingFailed
    case invalidInput

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed: return "Не удалось загрузить модель CoreML"
        case .tokenizationFailed: return "Ошибка токенизации текста"
        case .encodingFailed: return "Ошибка кодирования"
        case .decodingFailed: return "Ошибка декодирования"
        case .invalidInput: return "Некорректный входной текст"
        }
    }
}

// MARK: - Загруженные модели

private struct LoadedModels: @unchecked Sendable {
    let encoder: NLLB_Encoder_128
    let decoder: NLLB_Decoder_128
    let tokenizer: NLLBTokenizer
}

// MARK: - Сервис перевода

final class NLLBTranslationService {
    static let shared = NLLBTranslationService()

    private let modelsTask: Task<LoadedModels?, Never>

    private init() {
        modelsTask = Task {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    do {
                        let config = MLModelConfiguration()
                        config.computeUnits = .cpuOnly
                        let encoder   = try NLLB_Encoder_128(configuration: config)
                        let decoder   = try NLLB_Decoder_128(configuration: config)
                        let tokenizer = NLLBTokenizer()
                        continuation.resume(returning: LoadedModels(encoder: encoder, decoder: decoder, tokenizer: tokenizer))
                    } catch {
                            continuation.resume(returning: nil)
                    }
                }
            }
        }
    }

    // MARK: - Перевод

    func translate(_ text: String, from sourceLang: String, to targetLang: String) async throws -> String {
        guard !text.isEmpty else { throw NLLBError.invalidInput }

        guard let m = await modelsTask.value else {
            throw NLLBError.modelLoadFailed
        }

        let sourceTokens = try m.tokenizer.tokenize(text, language: sourceLang)
        guard !sourceTokens.isEmpty else { throw NLLBError.tokenizationFailed }

        let encoderInput = try createEncoderInput(tokens: sourceTokens)
        guard let encoderOutput = try? await m.encoder.prediction(input: encoderInput) else {
            throw NLLBError.encodingFailed
        }

        let targetLangToken = m.tokenizer.languageToken(for: targetLang)
        let decodedTokens = try await decode(
            encoderOutput: encoderOutput,
            encoderAttentionMask: encoderInput.attention_mask,
            decoder: m.decoder,
            startToken: targetLangToken,
            tokenizer: m.tokenizer
        )

        let result = m.tokenizer.detokenize(decodedTokens)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Приватные методы

    private func createEncoderInput(tokens: [Int]) throws -> NLLB_Encoder_128Input {
        let maxLen = 128
        let paddedTokens = tokens.count > maxLen ? Array(tokens.prefix(maxLen)) : tokens + Array(repeating: 1, count: maxLen - tokens.count)

        let shape = [1, NSNumber(value: maxLen)] as [NSNumber]
        guard let inputIds = try? MLMultiArray(shape: shape, dataType: .int32),
              let attentionMask = try? MLMultiArray(shape: shape, dataType: .int32) else {
            throw NLLBError.encodingFailed
        }

        for i in 0..<maxLen {
            inputIds[[0, i] as [NSNumber]] = NSNumber(value: paddedTokens[i])
            attentionMask[[0, i] as [NSNumber]] = NSNumber(value: i < tokens.count ? 1 : 0)
        }

        return NLLB_Encoder_128Input(input_ids: inputIds, attention_mask: attentionMask)
    }

    private func decode(
        encoderOutput: NLLB_Encoder_128Output,
        encoderAttentionMask: MLMultiArray,
        decoder: NLLB_Decoder_128,
        startToken: Int,
        tokenizer: NLLBTokenizer
    ) async throws -> [Int] {
        let eosToken = 2
        var decodedTokens: [Int] = [eosToken, startToken]
        let maxLength = 50

        for _ in 0..<maxLength {
            let decoderInput = try createDecoderInput(
                tokens: decodedTokens,
                encoderOutput: encoderOutput,
                encoderAttentionMask: encoderAttentionMask
            )

            guard let decoderOutput = try? await decoder.prediction(input: decoderInput) else {
                throw NLLBError.decodingFailed
            }

            let nextToken = getNextToken(from: decoderOutput, tokenCount: decodedTokens.count)

            if nextToken == eosToken {
                break
            }

            decodedTokens.append(nextToken)
        }

        return decodedTokens
    }

    private func createDecoderInput(
        tokens: [Int],
        encoderOutput: NLLB_Encoder_128Output,
        encoderAttentionMask: MLMultiArray
    ) throws -> NLLB_Decoder_128Input {
        let maxLen = 128
        let paddedTokens = tokens.count > maxLen ? Array(tokens.prefix(maxLen)) : tokens + Array(repeating: 1, count: maxLen - tokens.count)

        let shape = [1, NSNumber(value: maxLen)] as [NSNumber]
        guard let decoderInputIds = try? MLMultiArray(shape: shape, dataType: .int32) else {
            throw NLLBError.decodingFailed
        }

        for i in 0..<maxLen {
            decoderInputIds[[0, i] as [NSNumber]] = NSNumber(value: paddedTokens[i])
        }

        return NLLB_Decoder_128Input(
            decoder_input_ids: decoderInputIds,
            encoder_hidden_states: encoderOutput.var_879,
            encoder_attention_mask: encoderAttentionMask
        )
    }

    private func getNextToken(from output: NLLB_Decoder_128Output, tokenCount: Int) -> Int {
        let logits    = output.var_1525
        let vocabSize = logits.shape[logits.shape.count - 1].intValue
        let seqDim    = logits.shape.count >= 2 ? logits.shape[logits.shape.count - 2].intValue : 1
        let lastStep  = min(tokenCount - 1, seqDim - 1)
        let rowStride = logits.strides.count >= 2
            ? logits.strides[logits.strides.count - 2].intValue
            : vocabSize

        switch logits.dataType {
        case .float32:
            let ptr    = logits.dataPointer.assumingMemoryBound(to: Float32.self)
            let offset = lastStep * rowStride
            var maxVal: Float32 = -.infinity
            var maxIdx: vDSP_Length = 0
            vDSP_maxvi(ptr + offset, 1, &maxVal, &maxIdx, vDSP_Length(vocabSize))
            return Int(maxIdx)

        case .float16:
            let f16    = logits.dataPointer.assumingMemoryBound(to: Float16.self)
            let offset = lastStep * rowStride
            let slice  = UnsafeBufferPointer(start: f16 + offset, count: vocabSize)
            var f32 = [Float](repeating: 0, count: vocabSize)
            vDSP.convertElements(of: slice, to: &f32)
            var maxVal: Float = -.infinity
            var maxIdx: vDSP_Length = 0
            vDSP_maxvi(&f32, 1, &maxVal, &maxIdx, vDSP_Length(vocabSize))
            return Int(maxIdx)

        default:
            let offset = lastStep * rowStride
            var maxValue: Float = -.infinity
            var maxIndex = 0
            for i in 0..<vocabSize {
                let v = logits[[0, lastStep, i] as [NSNumber]].floatValue
                if v > maxValue { maxValue = v; maxIndex = i }
            }
            return maxIndex
        }
    }
}

// MARK: - Токенизатор (SentencePiece)

final class NLLBTokenizer {

    private var processor: SentencepieceTokenizer?

    // Специальные токены
    private let bosToken = 0
    private let padToken = 1
    private let eosToken = 2
    private let unkToken = 3

    private let languageTokens: [String: Int] = [
        "rus_Cyrl": 256147,  // Русский
        "eng_Latn": 256047   // Английский
    ]

    init() {
        loadProcessor()
    }

    private func loadProcessor() {
        guard let modelPath = Bundle.main.path(forResource: "sentencepiece.bpe", ofType: "model") else {
            return
        }

        do {
            processor = try SentencepieceTokenizer(modelPath: modelPath, tokenOffset: 1)
        } catch {}
    }

    func tokenize(_ text: String, language: String) throws -> [Int] {
        guard let processor = processor else {
            throw NLLBError.tokenizationFailed
        }

        let pieces = try processor.encode(text)

        let langToken = languageToken(for: language)
        var tokens = [langToken]
        tokens.append(contentsOf: pieces)
        tokens.append(eosToken)

        return tokens
    }

    func detokenize(_ tokens: [Int]) -> String {
        guard let processor = processor else {
            return ""
        }

        let filteredTokens = tokens.filter { $0 > 3 && $0 < 256000 }

        do {
            let raw = try processor.decode(filteredTokens)
            var result = raw.unicodeScalars
                .filter { $0 != Unicode.Scalar(0xFFFD) }
                .reduce(into: "") { $0.append(Character($1)) }
            while let last = result.unicodeScalars.last {
                let v = last.value
                let ok = v <= 0x007F
                      || (v >= 0x0400 && v <= 0x04FF)
                      || CharacterSet.whitespaces.contains(last)
                if ok { break }
                result = String(result.dropLast())
            }
            return result
        } catch {
            return ""
        }
    }

    func languageToken(for language: String) -> Int {
        let key: String
        switch language.lowercased() {
        case "russian", "русский":
            key = "rus_Cyrl"
        case "english", "английский":
            key = "eng_Latn"
        default:
            key = "eng_Latn"
        }
        return languageTokens[key] ?? languageTokens["eng_Latn"]!
    }
}
