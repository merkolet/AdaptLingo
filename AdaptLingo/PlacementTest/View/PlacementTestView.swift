//
//  PlacementTestView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

struct PlacementTestView: View {
    @StateObject private var viewModel = PlacementTestViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }

    var body: some View {
        if viewModel.isCompleted {
            PlacementTestResultView(
                level: viewModel.assignedLevel,
                score: viewModel.score,
                total: viewModel.questions.count,
                reason: viewModel.levelReason
            ) {
                Task { await viewModel.saveResult() }
                dismiss()
                onComplete()
            }
        } else if viewModel.isLoadingQuestions {
            statusScreen(
                icon: "ellipsis",
                iconIsAnimated: true,
                title: "Генерируем тест",
                subtitle: "Создаём персональные вопросы для тебя…"
            )
        } else if let error = viewModel.loadingError {
            errorScreen(message: error)
        } else if viewModel.isEvaluating {
            statusScreen(
                icon: "brain.head.profile",
                iconIsAnimated: false,
                title: "Анализируем результаты",
                subtitle: "Искусственный интеллект определяет твой уровень…"
            )
        } else if !viewModel.questions.isEmpty {
            questionScreen
        }
    }

    // MARK: - Экран статуса (загрузка / оценка)

    private func statusScreen(
        icon: String,
        iconIsAnimated: Bool,
        title: String,
        subtitle: String
    ) -> some View {
        ZStack {
            appGradient.ignoresSafeArea()
            Circle()
                .fill(Color.indigo.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 100, y: -120)

            VStack(spacing: 24) {
                if iconIsAnimated {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.indigo)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.indigo)
                        .symbolEffect(.pulse)
                }
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }

    // MARK: - Экран ошибки

    private func errorScreen(message: String) -> some View {
        ZStack {
            appGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 52))
                    .foregroundStyle(.orange)
                Text("Не удалось загрузить тест")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button {
                    Task { await viewModel.loadQuestions() }
                } label: {
                    Label("Попробовать снова", systemImage: "arrow.clockwise")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32).padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red:0.38,green:0.3,blue:1), Color(red:0.6,green:0.2,blue:0.9)],
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Экран вопроса

    private var questionScreen: some View {
        ZStack {
            appGradient.ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: 120, y: -100)

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        questionCard
                        answersStack
                    }
                    .padding(.horizontal, 20)
                }

                nextButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Прогресс-шапка

    private var progressHeader: some View {
        let q = viewModel.currentQuestion
        return VStack(spacing: 10) {
            HStack {
                Label(q.type.displayName, systemImage: q.type.icon)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.1)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * viewModel.progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 8)

            HStack {
                DifficultyBadge(level: viewModel.currentQuestion.difficulty)
                Spacer()
            }
        }
    }

    // MARK: - Карточка вопроса

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.currentQuestion.instruction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.currentQuestion.questionText)
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Варианты ответов

    private var answersStack: some View {
        VStack(spacing: 10) {
            ForEach(Array(viewModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                AnswerOptionButton(text: option, state: viewModel.answerState(for: index)) {
                    viewModel.selectAnswer(index)
                }
            }
        }
    }

    // MARK: - Кнопка Далее

    private var nextButton: some View {
        let isEnabled = viewModel.selectedAnswerIndex != nil
        let title = viewModel.isLastQuestion ? "Завершить тест" : "Далее →"
        return Button { viewModel.nextQuestion() } label: {
            Text(title).fontWeight(.semibold).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: isEnabled
                            ? [Color(red:0.38,green:0.3,blue:1), Color(red:0.6,green:0.2,blue:0.9)]
                            : [Color.primary.opacity(0.12), Color.primary.opacity(0.12)],
                        startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Бейдж сложности

private struct DifficultyBadge: View {
    let level: String

    private var color: Color {
        switch level {
        case "A1": return .green
        case "A2": return .teal
        case "B1": return .blue
        case "B2": return .indigo
        default: return .purple   // C1
        }
    }

    var body: some View {
        Text(level)
            .font(.caption2).fontWeight(.bold)
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Кнопка варианта ответа

struct AnswerOptionButton: View {
    let text: String
    let state: AnswerButtonState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text).font(.body).multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if state == .selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red:0.5,green:0.4,blue:1))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(
                state == .selected
                    ? Color(red:0.38,green:0.3,blue:1).opacity(0.2)
                    : Color.primary.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(state == .selected
                            ? Color(red:0.5,green:0.4,blue:1).opacity(0.7)
                            : Color.primary.opacity(0.1),
                            lineWidth: state == .selected ? 1.5 : 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}

#Preview { PlacementTestView(onComplete: {}) }
