//
//  AdaptLingoApp.swift
//  AdaptLingo
//
//  Created by Sergey on 03.02.2026.
//

import SwiftUI
import Supabase

@main
struct AdaptLingoApp: App {
    @State private var showNewPassword = false
    @AppStorage("app_theme") private var themeRaw: String = AppTheme.dark.rawValue

    private var colorScheme: ColorScheme? {
        AppTheme(rawValue: themeRaw)?.colorScheme
    }

    @AppStorage("onboarding_done") private var onboardingDone = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingDone {
                    AuthView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(colorScheme)
                .fullScreenCover(isPresented: $showNewPassword) {
                    NewPasswordView(onClose: { showNewPassword = false })
                        .preferredColorScheme(colorScheme)
                }
                .onOpenURL { url in
                    Task {
                        do {
                            try await supabase.auth.handle(url)
                            showNewPassword = true
                        } catch {}
                    }
                }
        }
    }
}
