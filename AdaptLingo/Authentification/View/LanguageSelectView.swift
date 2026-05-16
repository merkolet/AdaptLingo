//
//  LanguageSelectView.swift
//  AdaptLingo
//
//  Created by Sergey on 16.05.2026.
//

import SwiftUI

struct LanguageSelectView: View {
    let onSelect: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient.appBackground(colorScheme).ignoresSafeArea()

            Circle()
                .fill(Color.indigo.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -220)

            Circle()
                .fill(Color.purple.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 130, y: 230)

            VStack(spacing: 0) {
                Spacer()

                // Заголовок
                VStack(spacing: 12) {
                    Text("🌍")
                        .font(.system(size: 64))

                    Text("Выбери язык")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Какой язык ты хочешь учить?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 52)

                VStack(spacing: 14) {
                    languageCard(flag: "🇬🇧", name: "Английский", subtitle: "English", available: true)
                    languageCard(flag: "🇪🇸", name: "Испанский",  subtitle: "Español", available: false)
                    languageCard(flag: "🇫🇷", name: "Французский", subtitle: "Français", available: false)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func languageCard(flag: String, name: String, subtitle: String, available: Bool) -> some View {
        Button { if available { onSelect() } } label: {
            HStack(spacing: 16) {
                Text(flag)
                    .font(.system(size: 42))

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(available ? .primary : .secondary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if available {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Скоро")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.4))
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        available
                            ? LinearGradient(
                                colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(
                                colors: [Color.primary.opacity(0.1), Color.primary.opacity(0.1)],
                                startPoint: .leading, endPoint: .trailing),
                        lineWidth: available ? 1.5 : 1
                    )
            )
            .opacity(available ? 1.0 : 0.55)
        }
        .disabled(!available)
    }
}
