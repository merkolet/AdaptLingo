//
//  ThemeManager.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI
import Combine

// MARK: - Варианты темы

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Менеджер темы

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var current: AppTheme

    private static let key = "app_theme"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? AppTheme.light.rawValue
        current = AppTheme(rawValue: raw) ?? .light
    }

    func set(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Self.key)
    }
}
