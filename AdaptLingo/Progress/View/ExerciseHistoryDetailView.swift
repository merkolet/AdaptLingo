//
//  ExerciseHistoryDetailView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

struct ExerciseHistoryDetailView: View {

    let group: ExerciseHistoryGroup
    let onClear: () async -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            LinearGradient.appBackground(colorScheme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    summaryCard
                    exercisesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle(group.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showClearConfirm = true
                } label: {
                    Text("Очистить")
                        .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "Очистить историю «\(group.displayName)»?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                Task {
                    await onClear()
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Карточка итога

    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(group.color.opacity(0.18)).frame(width: 56, height: 56)
                Image(systemName: group.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(group.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("\(group.correct) из \(group.items.count) верно")
                    .font(.headline)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.1)).frame(height: 8)
                        Capsule()
                            .fill(group.color)
                            .frame(width: geo.size.width * Double(group.accuracy) / 100.0, height: 8)
                    }
                }
                .frame(height: 8)
                Text("Точность: \(group.accuracy)%")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.top, 8)
    }

    // MARK: - Список упражнений

    private var exercisesSection: some View {
        VStack(spacing: 12) {
            ForEach(group.items) { item in
                ExerciseHistoryCard(item: item, accentColor: group.color)
            }
        }
    }
}

// MARK: - Карточка одного упражнения

private struct ExerciseHistoryCard: View {
    let item: ExerciseHistoryItem
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(item.isCorrect ? .green : .red)
                    .font(.system(size: 20))
                    .padding(.top, 1)
                Text(item.question)
                    .font(.subheadline).fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                answerRow(label: "Правильный ответ",
                          text : item.correctAnswer,
                          color: .green,
                          icon : "checkmark.circle.fill")

                if !item.isCorrect {
                    answerRow(label: "Ваш ответ",
                              text : item.userAnswer,
                              color: .red,
                              icon : "xmark.circle.fill")
                }

                if !item.explanation.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Объяснение")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text(item.explanation)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(item.isCorrect ? Color.green.opacity(0.25) : Color.red.opacity(0.25),
                        lineWidth: 1)
        )
    }

    private func answerRow(label: String, text: String, color: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color).font(.caption).padding(.top, 2)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(text).font(.subheadline).foregroundStyle(color).fontWeight(.medium)
            }
        }
    }
}
