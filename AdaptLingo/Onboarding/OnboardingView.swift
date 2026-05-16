//
//  OnboardingView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

// MARK: - Модель страницы

private struct OnboardingPage {
    let icon: String
    let iconColors: [Color]
    let title: String
    let subtitle: String
}

// MARK: - Контент страниц

private let pages: [OnboardingPage] = [
    OnboardingPage(
        icon: "text.book.closed.fill",
        iconColors: [.indigo, .purple],
        title: "Добро пожаловать в AdaptLingo",
        subtitle: "Умный помощник для изучения английского языка прямо на твоём iPhone"
    ),
    OnboardingPage(
        icon: "brain.head.profile",
        iconColors: [.blue, .indigo],
        title: "Адаптивные упражнения",
        subtitle: "AI подстраивает задания под твой уровень — от A1 до C1 — и растёт вместе с тобой"
    ),
    OnboardingPage(
        icon: "chart.line.uptrend.xyaxis",
        iconColors: [.purple, .pink],
        title: "Следи за прогрессом",
        subtitle: "Стрики, XP и статистика помогут сохранять мотивацию каждый день"
    ),
    OnboardingPage(
        icon: "sparkles",
        iconColors: [.yellow, .orange],
        title: "Готов начать?",
        subtitle: "Пройди короткий тест — и мы точно определим твой уровень английского"
    )
]

// MARK: - Главный экран онбординга

struct OnboardingView: View {
    @AppStorage("onboarding_done") private var onboardingDone = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme

    private var appGradient: LinearGradient { .appBackground(colorScheme) }
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            appGradient.ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -90, y: -200)

            Circle()
                .fill(Color.purple.opacity(0.25))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 110, y: 220)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 32) {
                    dotsIndicator
                    actionButton
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Страница

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.iconColors.map { $0.opacity(0.18) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 16)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Индикатор точек

    private var dotsIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.indigo : Color.primary.opacity(0.2))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Кнопка «Далее» / «Начать»

    private var actionButton: some View {
        Button {
            if isLastPage {
                onboardingDone = true
            } else {
                withAnimation { currentPage += 1 }
            }
        } label: {
            Text(isLastPage ? "Начать" : "Далее")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.38, green: 0.3, blue: 1), Color(red: 0.6, green: 0.2, blue: 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.indigo.opacity(0.4), radius: 10, y: 4)
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
