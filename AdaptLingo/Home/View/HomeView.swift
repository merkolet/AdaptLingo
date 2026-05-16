//
//  HomeView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var imageManager = ProfileImageManager.shared
    @State private var photoPickerItem: PhotosPickerItem?
    @Environment(\.colorScheme) var colorScheme

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Доброе утро,"
        case 12..<17: return "Добрый день,"
        case 17..<22: return "Добрый вечер,"
        default: return "Доброй ночи,"
        }
    }

    private var xpProgress: Double {
        let thresholds = ["A1": 500, "A2": 1000, "B1": 2000, "B2": 3500, "C1": 5000]
        let max = Double(thresholds[viewModel.level] ?? 500)
        return max > 0 ? min(Double(viewModel.xp) / max, 1.0) : 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appGradient.ignoresSafeArea()

                Circle()
                    .fill(Color.indigo.opacity(0.25))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 130, y: -60)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerRow
                        heroDailyCard
                        statsRow
                        xpProgressCard
                        activityCalendarCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .task { await viewModel.loadData() }
            .refreshable { await viewModel.loadData() }
        }
    }

    // MARK: - Шапка

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.displayName.isEmpty ? "Привет!" : viewModel.displayName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.45, blue: 1.0), Color(red: 0.75, green: 0.35, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                avatarCircle(size: 52)
            }
            .onChange(of: photoPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        imageManager.save(img)
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func avatarCircle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
            if let img = imageManager.avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Hero-карточка

    private var heroDailyCard: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(red:0.2,green:0.15,blue:0.9), Color(red:0.5,green:0.15,blue:0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            Circle().fill(.white.opacity(0.07)).frame(width: 170, height: 170).offset(x: 210, y: -55)
            Circle().fill(.white.opacity(0.05)).frame(width: 90, height: 90).offset(x: 255, y: 80)

            VStack(alignment: .leading, spacing: 14) {
                Label("Дневной урок", systemImage: "sun.max.fill")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Продолжи\nучить английский!")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineSpacing(3)
                NavigationLink(destination: LessonsView()) {
                    HStack(spacing: 6) {
                        Text("Начать").fontWeight(.bold)
                        Image(systemName: "arrow.right").font(.subheadline)
                    }
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                }
            }
            .padding(22)
        }
        .frame(minHeight: 180)
        .shadow(color: Color(red:0.2,green:0.15,blue:0.9).opacity(0.5), radius: 20, y: 8)
    }

    // MARK: - Статистика

    private var statsRow: some View {
        HStack(spacing: 0) {
            QuickStat(icon: "flame.fill", color: .orange, value: "\(viewModel.streakDays)", label: "Дней подряд")
            Rectangle().fill(Color.primary.opacity(0.1)).frame(width: 1, height: 38)
            QuickStat(icon: "star.fill", color: .yellow, value: "\(viewModel.xp)", label: "Очки XP")
            Rectangle().fill(Color.primary.opacity(0.1)).frame(width: 1, height: 38)
            QuickStat(icon: "checkmark.seal.fill", color: .green, value: "\(viewModel.totalDone)", label: "Заданий")
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Прогресс XP

    private var xpProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Прогресс уровня", systemImage: "trophy.fill")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(viewModel.totalDone > 0 ? "Точность \(viewModel.accuracy)%" : "—")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.1)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * xpProgress, height: 10)
                        .animation(.spring(duration: 0.9, bounce: 0.2), value: xpProgress)
                }
            }
            .frame(height: 10)
            HStack {
                Text("\(viewModel.xp) XP").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("Уровень \(viewModel.level)").font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Календарь активности

    private var activityCalendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Активность за месяц", systemImage: "calendar")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }

            let days = calendarDaysForMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<days.count, id: \.self) { i in
                    calendarDayCell(days[i])
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func calendarDayCell(_ date: Date?) -> some View {
        if let date {
            let cal = Calendar.current
            let isToday = cal.isDateInToday(date)
            let dayStr = dayFormatter.string(from: date)
            let isActive = viewModel.activeDates.contains(dayStr)
            let isFuture = date > Date() && !isToday
            let day = cal.component(.day, from: date)

            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isToday  ? Color.indigo :
                              isActive ? Color.green.opacity(0.25) : Color.clear)
                        .frame(width: 30, height: 30)
                    Text("\(day)")
                        .font(.caption).fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(isToday  ? .white :
                                         isFuture ? Color.primary.opacity(0.3) : .primary)
                }
                Circle()
                    .fill(isActive && !isToday ? Color.green : Color.clear)
                    .frame(width: 4, height: 4)
            }
        } else {
            Color.clear.frame(height: 36)
        }
    }

    private func calendarDaysForMonth() -> [Date?] {
        let cal = Calendar.current
        var calWithMonday = cal
        calWithMonday.firstWeekday = 2
        let now   = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let firstDay = cal.date(from: comps),
              let range    = cal.range(of: .day, in: .month, for: now) else { return [] }

        let weekday = cal.component(.weekday, from: firstDay)
        let offset  = (weekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
}

// MARK: - QuickStat

struct QuickStat: View {
    let icon: String; let color: Color; let value: String; let label: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text(value).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(.primary)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { HomeView() }
