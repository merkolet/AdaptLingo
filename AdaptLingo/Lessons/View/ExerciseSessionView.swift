//
//  ExerciseSessionView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

// MARK: - Главный экран сессии

struct ExerciseSessionView: View {
    @StateObject private var viewModel: ExerciseSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }

    init(exerciseType: Exercise.ExerciseType) {
        _viewModel = StateObject(wrappedValue: ExerciseSessionViewModel(exerciseType: exerciseType))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.loadError {
                errorView(message: error)
            } else if viewModel.sessionComplete {
                SessionResultView(viewModel: viewModel, onDismiss: { dismiss() })
            } else if let exercise = viewModel.currentExercise {
                questionView(exercise: exercise)
            }
        }
        .navigationTitle(viewModel.exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadExercises() }
    }

    // MARK: - Загрузка

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
            VStack(spacing: 6) {
                Text("Подготавливаем задания…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Генерируем 15 упражнений вашего уровня")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appGradient.ignoresSafeArea())
    }

    // MARK: - Ошибка

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.orange)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.loadExercises() }
            } label: {
                Label("Попробовать снова", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.indigo)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appGradient.ignoresSafeArea())
    }

    // MARK: - Экран вопроса

    private func questionView(exercise: Exercise) -> some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 14) {
                    instructionAndQuestion(exercise: exercise)
                    optionsStack(exercise: exercise)
                    if viewModel.isAnswerRevealed {
                        feedbackCard(exercise: exercise)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isAnswerRevealed)
            }

            if viewModel.isAnswerRevealed {
                nextButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(appGradient.ignoresSafeArea())
    }

    // MARK: - Прогресс-шапка

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label(viewModel.exerciseType.displayName, systemImage: viewModel.exerciseType.icon)
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.indigo)
                Spacer()
                Text("\(viewModel.currentIndex + 1) / \(viewModel.exercises.count)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Color(.systemFill)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * viewModel.progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Инструкция + вопрос

    private func instructionAndQuestion(exercise: Exercise) -> some View {
        VStack(spacing: 10) {
            HStack {
                ExerciseDifficultyBadge(level: exercise.difficulty)
                Spacer()
            }
            Text(exercise.instruction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(exercise.question)
                .font(.title3).fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }

    // MARK: - Варианты ответов

    private func optionsStack(exercise: Exercise) -> some View {
        VStack(spacing: 10) {
            ForEach(exercise.options, id: \.self) { option in
                ExerciseOptionButton(
                    text: option,
                    state: viewModel.optionState(for: option),
                    isDisabled: viewModel.isAnswerRevealed
                ) {
                    viewModel.selectAnswer(option)
                }
            }
        }
    }

    // MARK: - Фидбек после ответа

    private func feedbackCard(exercise: Exercise) -> some View {
        let isCorrect = exercise.userAnswer == exercise.correctAnswer
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
                    .font(.title3)
                Text(isCorrect ? "Правильно!" : "Неверно")
                    .fontWeight(.semibold)
                    .foregroundStyle(isCorrect ? .green : .red)
            }

            if !isCorrect {
                HStack(spacing: 6) {
                    Text("Правильный ответ:")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(exercise.correctAnswer)
                        .font(.subheadline).fontWeight(.semibold)
                }
            }

            Divider()

            Text(exercise.explanation)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(isCorrect ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Кнопка «Далее»

    private var nextButton: some View {
        Button {
            viewModel.nextQuestion()
        } label: {
            Text(viewModel.isLastQuestion ? "Завершить" : "Далее →")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Кнопка варианта ответа

struct ExerciseOptionButton: View {
    let text: String
    let state: ExerciseOptionState
    let isDisabled: Bool
    let action: () -> Void

    private var bgColor: Color {
        switch state {
        case .normal: return Color.primary.opacity(0.08)
        case .correct: return Color.green.opacity(0.15)
        case .wrong: return Color.red.opacity(0.15)
        }
    }
    private var borderColor: Color {
        switch state {
        case .normal: return Color.primary.opacity(0.12)
        case .correct: return .green
        case .wrong: return .red
        }
    }
    private var borderWidth: CGFloat { state == .normal ? 1 : 2 }
    private var trailingIcon: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        case .normal: return nil
        }
    }
    private var iconColor: Color { state == .correct ? .green : .red }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
            .background(bgColor)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: borderWidth))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.primary)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

// MARK: - Экран результата сессии

struct SessionResultView: View {
    @ObservedObject var viewModel: ExerciseSessionViewModel
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }

    private var scorePercent: Int {
        viewModel.exercises.isEmpty ? 0
            : Int(Double(viewModel.score) / Double(viewModel.exercises.count) * 100)
    }
    private var resultIcon: String {
        switch scorePercent {
        case 80...100: return "trophy.fill"
        case 60...79: return "party.popper.fill"
        case 40...59: return "bolt.fill"
        default: return "books.vertical.fill"
        }
    }
    private var resultIconColor: Color {
        switch scorePercent {
        case 80...100: return .yellow
        case 60...79: return .indigo
        case 40...59: return .orange
        default: return .blue
        }
    }
    private var resultMessage: String {
        switch scorePercent {
        case 80...100: return "Отличный результат!"
        case 60...79: return "Хорошая работа!"
        case 40...59: return "Продолжай практиковаться!"
        default: return "Не сдавайся, попробуй ещё!"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summarySection
                    .padding(.top, 28)

                if !viewModel.wrongExercises.isEmpty {
                    errorReviewSection
                }

                actionButtons
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .background(appGradient.ignoresSafeArea())
    }

    // MARK: - Итоговая секция

    private var summarySection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(resultIconColor.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Image(systemName: resultIcon)
                        .font(.system(size: 42))
                        .foregroundStyle(resultIconColor)
                }
                Text(resultMessage)
                    .font(.title2).fontWeight(.bold)
                Text("\(viewModel.score) из \(viewModel.exercises.count) правильно")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            // Три бейджа
            HStack(spacing: 12) {
                ResultStatBadge(icon: "star.fill", color: .yellow,
                                value: "+\(viewModel.xpEarned)", label: "XP")
                ResultStatBadge(icon: "checkmark.circle.fill", color: .green,
                                value: "\(viewModel.score)", label: "Верно")
                ResultStatBadge(icon: "xmark.circle.fill", color: .red,
                                value: "\(viewModel.exercises.count - viewModel.score)", label: "Ошибок")
            }
        }
    }

    // MARK: - Разбор ошибок

    private var errorReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("Разбор ошибок")
                    .font(.title3).fontWeight(.bold)
                Spacer()
                Text("\(viewModel.wrongExercises.count) шт.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ForEach(viewModel.wrongExercises) { exercise in
                ErrorReviewCard(exercise: exercise)
            }
        }
    }

    // MARK: - Кнопки

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { viewModel.retry() } label: {
                Label("Ещё раз", systemImage: "arrow.clockwise")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button { onDismiss() } label: {
                Text("В меню")
                    .fontWeight(.semibold)
                    .foregroundStyle(.indigo)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.indigo.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Карточка одной ошибки

private struct ErrorReviewCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text(exercise.question)
                .font(.body).fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                answerRow(
                    icon : "checkmark.circle.fill",
                    color: .green,
                    label: "Правильный ответ",
                    text : exercise.correctAnswer
                )

                if let ua = exercise.userAnswer {
                    answerRow(
                        icon : "xmark.circle.fill",
                        color: .red,
                        label: "Ваш ответ",
                        text : ua
                    )
                }

                if !exercise.explanation.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.subheadline)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Объяснение")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(exercise.explanation)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    private func answerRow(icon: String, color: Color, label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption).foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(color)
            }
        }
    }
}

struct ResultStatBadge: View {
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Бейдж сложности

struct ExerciseDifficultyBadge: View {
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

#Preview {
    NavigationStack {
        ExerciseSessionView(exerciseType: .fillBlank)
    }
}
