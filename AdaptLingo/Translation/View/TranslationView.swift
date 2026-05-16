//
//  TranslationView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                appGradient.ignoresSafeArea()

                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(x: 130, y: 160)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if viewModel.isOfflineFallback {
                            offlineBanner
                        }
                        languageToggleRow
                        inputCard
                        if viewModel.isLoading {
                            loadingCard
                        } else if let error = viewModel.errorMessage {
                            errorCard(message: error)
                        } else if !viewModel.resultText.isEmpty {
                            resultCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Перевод")
            .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .onTapGesture { isInputFocused = false }
            .onAppear { _ = NLLBTranslationService.shared }
        }
    }

    // MARK: - Оффлайн-баннер

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Локальный перевод")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Text("Нет интернета. Используется CoreML — качество перевода снижено.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Переключатель языков

    private var languageToggleRow: some View {
        HStack {
            Text(viewModel.sourceLang)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)

            Button { viewModel.swapLanguages() } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
            }

            Text(viewModel.targetLang)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.top, 8)
    }

    // MARK: - Поле ввода

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.sourceLang)
                .font(.caption).foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("Введите слово или фразу…")
                        .foregroundStyle(.primary.opacity(0.3))
                        .padding(.top, 8).padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.inputText)
                    .focused($isInputFocused)
                    .frame(minHeight: 100, maxHeight: 160)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 10) {
                if !viewModel.inputText.isEmpty {
                    Button {
                        viewModel.clear(); isInputFocused = false
                    } label: {
                        Label("Очистить", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    isInputFocused = false; viewModel.translate()
                } label: {
                    Text("Перевести")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(
                            viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AnyShapeStyle(Color.primary.opacity(0.12))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Color(red:0.38,green:0.3,blue:1), Color(red:0.6,green:0.2,blue:0.9)],
                                    startPoint: .leading, endPoint: .trailing))
                        )
                        .clipShape(Capsule())
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Загрузка

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Переводим…").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Ошибка

    private func errorCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message).font(.subheadline).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Результат

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.targetLang).font(.caption).foregroundStyle(.secondary)
            Text(viewModel.resultText)
                .font(.body).foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red:0.5,green:0.4,blue:1).opacity(0.5), lineWidth: 1.5)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

#Preview { TranslationView() }
