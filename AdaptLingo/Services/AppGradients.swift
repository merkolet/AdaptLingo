//
//  AppGradients.swift
//  AdaptLingo
//

import SwiftUI

extension LinearGradient {
    /// Основной фон приложения — тёмный или очень светлый лавандовый
    static func appBackground(_ colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.22),
                    Color(red: 0.18, green: 0.04, blue: 0.36),
                    Color(red: 0.04, green: 0.08, blue: 0.28)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.97, blue: 1.00),
                    Color(red: 0.95, green: 0.94, blue: 1.00),
                    Color(red: 0.97, green: 0.97, blue: 1.00)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func navBarColor(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.07, green: 0.06, blue: 0.24)
            : Color(red: 0.98, green: 0.97, blue: 1.00)
    }
}
