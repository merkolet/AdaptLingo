//
//  LessonsView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI
internal import Auth
import Supabase

struct LessonsView: View {
    @State private var userLevel = "A1"
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                appGradient.ignoresSafeArea()

                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: -100, y: 100)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        levelBanner
                        exerciseSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Уроки")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .task { await loadLevel() }
        }
    }

    private func loadLevel() async {
        do {
            let user = try await supabase.auth.user()
            userLevel = UserDefaults.standard.string(forKey: "level_\(user.id)") ?? "A1"
        } catch {}
        ExercisePrefetchService.shared.prefetchAll(level: userLevel)
    }

    private var levelBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .shadow(color: .blue.opacity(0.4), radius: 6, y: 3)
                Text(userLevel)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Уровень \(userLevel) — \(levelName(userLevel))")
                    .font(.headline).foregroundStyle(.primary)
                Text("Выбери тип задания ниже")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .padding(.top, 8)
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Типы заданий")
                .font(.headline).foregroundStyle(.primary)
                .padding(.leading, 2)
            ForEach(LessonCard.all) { card in
                NavigationLink(destination: ExerciseSessionView(exerciseType: card.exerciseType)) {
                    LessonCardRow(card: card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func levelName(_ level: String) -> String {
        switch level {
        case "A1": return "Начинающий"
        case "A2": return "Элементарный"
        case "B1": return "Средний"
        case "B2": return "Выше среднего"
        case "C1": return "Продвинутый"
        default: return "Начинающий"
        }
    }

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
}

// MARK: - Данные карточек

struct LessonCard: Identifiable {
    let id = UUID()
    let icon: String
    let gradientColors: [Color]
    let title: String
    let description: String
    let exerciseType: Exercise.ExerciseType

    static let all: [LessonCard] = [
        LessonCard(icon: "pencil.line", gradientColors: [.blue, .cyan],
                   title: "Заполни пропуск", description: "Вставь нужное слово в предложение", exerciseType: .fillBlank),
        LessonCard(icon: "checkmark.circle.fill", gradientColors: [.purple, .indigo],
                   title: "Выбор варианта", description: "Выбери правильную форму слова или фразы",  exerciseType: .multipleChoice),
        LessonCard(icon: "arrow.left.arrow.right", gradientColors: [.teal, Color(red:0.1,green:0.7,blue:0.55)],
                   title: "Перевод фраз", description: "Выбери правильный перевод слова или фразы", exerciseType: .translation)
    ]
}

// MARK: - Строка карточки

struct LessonCardRow: View {
    let card: LessonCard
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: card.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: card.gradientColors[0].opacity(0.45), radius: 6, y: 3)
                Image(systemName: card.icon).font(.title2).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(card.title).font(.headline).foregroundStyle(.primary)
                Text(card.description).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}

#Preview { LessonsView() }
