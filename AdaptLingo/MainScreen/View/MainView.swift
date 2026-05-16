//
//  MainView.swift
//  AdaptLingo
//
//  Created by Sergey on 06.04.2026.
//

import SwiftUI
import Supabase

struct MainView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app_theme") private var themeRaw: String = AppTheme.light.rawValue

    private var colorScheme: ColorScheme? {
        AppTheme(rawValue: themeRaw)?.colorScheme
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }

            LessonsView()
                .tabItem {
                    Label("Уроки", systemImage: "book.fill")
                }

            TranslationView()
                .tabItem {
                    Label("Перевод", systemImage: "globe")
                }

            UserProgressView()
                .tabItem {
                    Label("Прогресс", systemImage: "chart.bar.fill")
                }

            ProfileView(onSignOut: { dismiss() })
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
        }
        .tint(.indigo)
        .preferredColorScheme(colorScheme)
        .task { await startExercisePrefetch() }
    }

    // MARK: - Предзагрузка упражнений

    private func startExercisePrefetch() async {
        do {
            let user  = try await supabase.auth.user()
            let level = UserDefaults.standard.string(forKey: "level_\(user.id)") ?? "A1"
            ExercisePrefetchService.shared.prefetchAll(level: level)
        } catch {}
    }
}

#Preview {
    MainView()
}
