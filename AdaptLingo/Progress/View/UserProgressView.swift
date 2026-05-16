//
//  UserProgressView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

struct UserProgressView: View {
    @StateObject private var viewModel = UserProgressViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                appGradient.ignoresSafeArea()

                Circle()
                    .fill(Color.indigo.opacity(0.22))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: -120, y: -80)

                Group {
                    if viewModel.isLoading {
                        VStack(spacing: 14) {
                            ProgressView().scaleEffect(1.1)
                            Text("Загружаем статистику…")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                levelHeroCard
                                statsGrid
                                if !viewModel.typeStats.isEmpty {
                                    typeStatsCard
                                }
                                achievementsCard
                                if !viewModel.recentHistory.isEmpty {
                                    historyCard
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 36)
                        }
                    }
                }
            }
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(LinearGradient.navBarColor(colorScheme), for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .task { await viewModel.loadData() }
            .refreshable { await viewModel.loadData() }
        }
    }

    // MARK: - Hero-карточка уровня

    private var levelHeroCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [Color(red:0.2,green:0.15,blue:0.9), Color(red:0.5,green:0.15,blue:0.8)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(.rect(topLeadingRadius:20, bottomLeadingRadius:0, bottomTrailingRadius:0, topTrailingRadius:20))

                Circle().fill(.white.opacity(0.07)).frame(width: 130, height: 130).offset(x: 20, y: -30)

                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(.white.opacity(0.2)).frame(width: 72, height: 72)
                        Circle().stroke(.white.opacity(0.4), lineWidth: 2).frame(width: 72, height: 72)
                        Text(viewModel.level).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Уровень \(viewModel.level)").font(.title2).fontWeight(.bold).foregroundStyle(.white)
                        Text(levelDescription(viewModel.level)).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                            Text("\(viewModel.xp) XP").font(.caption).fontWeight(.medium).foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    Spacer()
                }
                .padding(20)
            }
            .frame(height: 130)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("До следующего уровня").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.xp) / \(viewModel.xpForNextLevel) XP").font(.caption).fontWeight(.semibold).foregroundStyle(.primary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.1)).frame(height: 10)
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * viewModel.xpProgress, height: 10)
                            .animation(.spring(duration: 0.9, bounce: 0.15), value: viewModel.xpProgress)
                    }
                }
                .frame(height: 10)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(.rect(topLeadingRadius:0, bottomLeadingRadius:20, bottomTrailingRadius:20, topTrailingRadius:0))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(color: Color(red:0.2,green:0.15,blue:0.9).opacity(0.4), radius: 16, y: 6)
        .padding(.top, 8)
    }

    // MARK: - Общая статистика

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Статистика").font(.headline).foregroundStyle(.primary).padding(.leading, 2)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProgressStatTile(icon: "flame.fill", color: .orange, value: "\(viewModel.streakDays)", label: "Серия дней")
                ProgressStatTile(icon: "star.fill", color: .yellow, value: "\(viewModel.xp)", label: "Всего XP")
                ProgressStatTile(icon: "checkmark.circle.fill", color: .green, value: "\(viewModel.totalDone)", label: "Заданий")
                ProgressStatTile(icon: "target", color: .red, value: viewModel.totalDone > 0 ? "\(viewModel.accuracy)%" : "—", label: "Точность")
            }
        }
    }

    // MARK: - Статистика по типам

    private var typeStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("По типам заданий").font(.headline).foregroundStyle(.primary).padding(.leading, 2)

            VStack(spacing: 10) {
                ForEach(viewModel.typeStats, id: \.type) { stat in
                    typeStatRow(stat)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }

    private func typeStatRow(_ stat: ExerciseTypeStat) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: stat.icon)
                    .foregroundStyle(stat.color)
                    .frame(width: 22)
                Text(stat.displayName)
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text("\(stat.correct)/\(stat.total)")
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(stat.accuracy)%")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(stat.accuracy >= 70 ? .green : stat.accuracy >= 40 ? .orange : .red)
                    .frame(width: 44, alignment: .trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08)).frame(height: 6)
                    Capsule()
                        .fill(stat.color)
                        .frame(width: geo.size.width * Double(stat.accuracy) / 100.0, height: 6)
                        .animation(.spring(duration: 0.8), value: stat.accuracy)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Достижения

    private var achievementsCard: some View {
        let achievements = buildAchievements()
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Достижения").font(.headline).foregroundStyle(.primary)
                Spacer()
                Text("\(unlockedCount) / \(achievements.count)").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.leading, 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                ForEach(achievements) { AchievementBadge(achievement: $0) }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }

    private func buildAchievements() -> [Achievement] {[
        // Стрики
        Achievement(icon:"flame.fill", color:.orange, title:"3 дня", isUnlocked: viewModel.streakDays >= 3),
        Achievement(icon:"flame.fill", color:.red, title:"7 дней", isUnlocked: viewModel.streakDays >= 7),
        Achievement(icon:"flame.fill", color:.pink, title:"14 дней", isUnlocked: viewModel.streakDays >= 14),
        Achievement(icon:"flame.fill", color:.purple, title:"30 дней", isUnlocked: viewModel.streakDays >= 30),
        // XP
        Achievement(icon:"star.fill", color:.yellow,  title:"100 XP", isUnlocked: viewModel.xp >= 100),
        Achievement(icon:"star.fill", color:.orange,  title:"500 XP", isUnlocked: viewModel.xp >= 500),
        Achievement(icon:"star.fill", color:.red, title:"1000 XP",  isUnlocked: viewModel.xp >= 1000),
        // Задания
        Achievement(icon:"checkmark.seal.fill", color:.blue, title:"10 зад.", isUnlocked: viewModel.totalDone >= 10),
        Achievement(icon:"checkmark.seal.fill", color:.indigo, title:"50 зад.", isUnlocked: viewModel.totalDone >= 50),
        Achievement(icon:"checkmark.seal.fill", color:.purple, title:"100 зад.", isUnlocked: viewModel.totalDone >= 100),
        // Уровни
        Achievement(icon:"trophy.fill", color:.yellow, title:"A2", isUnlocked: ["A2","B1","B2","C1"].contains(viewModel.level)),
        Achievement(icon:"trophy.fill", color:.orange, title:"B1", isUnlocked: ["B1","B2","C1"].contains(viewModel.level)),
        Achievement(icon:"trophy.fill", color:.red, title:"B2", isUnlocked: ["B2","C1"].contains(viewModel.level)),
        Achievement(icon:"trophy.fill", color:.purple, title:"C1", isUnlocked: viewModel.level == "C1"),
        // Точность
        Achievement(icon:"target", color:.green, title:"70%+", isUnlocked: viewModel.accuracy >= 70),
        Achievement(icon:"target", color:.mint, title:"90%+", isUnlocked: viewModel.accuracy >= 90),
    ]}

    // MARK: - История упражнений (сгруппированная по типам)

    private var historyGroups: [ExerciseHistoryGroup] {
        let defs: [(String, String, String, Color)] = [
            ("multiple_choice", "Грамматика", "checkmark.circle", .green),
            ("fill_blank", "Пропуски", "pencil.line", .blue),
            ("translation", "Перевод", "arrow.left.arrow.right", .purple),
        ]
        return defs.compactMap { raw, name, icon, color in
            let items = viewModel.recentHistory.filter { $0.exerciseType == raw }
            guard !items.isEmpty else { return nil }
            return ExerciseHistoryGroup(typeRaw: raw, displayName: name, icon: icon, color: color, items: items)
        }
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние упражнения")
                .font(.headline).foregroundStyle(.primary).padding(.leading, 2)

            ForEach(historyGroups, id: \.typeRaw) { group in
                NavigationLink(destination: ExerciseHistoryDetailView(
                    group: group,
                    onClear: { await viewModel.clearHistory(exerciseType: group.typeRaw) }
                )) {
                    historyGroupButton(group)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func historyGroupButton(_ group: ExerciseHistoryGroup) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [group.color, group.color.opacity(0.7)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .shadow(color: group.color.opacity(0.4), radius: 6, y: 3)
                Image(systemName: group.icon)
                    .font(.title2).foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.displayName)
                    .font(.headline).foregroundStyle(.primary)
                Text("\(group.items.count) заданий · \(group.accuracy)% верно")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(group.color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Вспомогательные

    private func levelDescription(_ l: String) -> String {
        switch l {
        case "A1": return "Начинающий"; case "A2": return "Элементарный"
        case "B1": return "Средний";    case "B2": return "Выше среднего"
        case "C1": return "Продвинутый"; default: return "Начинающий"
        }
    }

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
}

// MARK: - Компоненты

struct ProgressStatTile: View {
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(.primary)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}

struct Achievement: Identifiable {
    let id = UUID(); let icon: String; let color: Color; let title: String; let isUnlocked: Bool
}

struct AchievementBadge: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.primary.opacity(0.08))
                    .frame(width: 52, height: 52)
                if achievement.isUnlocked {
                    Circle().stroke(achievement.color.opacity(0.5), lineWidth: 2).frame(width: 52, height: 52)
                }
                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(achievement.isUnlocked ? achievement.color : .secondary)
            }
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(achievement.isUnlocked ? .medium : .regular)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .opacity(achievement.isUnlocked ? 1 : 0.55)
    }
}

// MARK: - Группа истории по типу упражнения

struct ExerciseHistoryGroup {
    let typeRaw: String
    let displayName: String
    let icon: String
    let color: Color
    let items: [ExerciseHistoryItem]
    var correct: Int { items.filter { $0.isCorrect }.count }
    var accuracy: Int { items.isEmpty ? 0 : Int(Double(correct) / Double(items.count) * 100) }
}

#Preview { UserProgressView() }
