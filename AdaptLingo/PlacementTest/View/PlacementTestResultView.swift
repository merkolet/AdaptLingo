//
//  PlacementTestResultView.swift
//  AdaptLingo
//
//  Created by Sergey on 15.04.2026.
//

import SwiftUI

struct PlacementTestResultView: View {
    let level: String
    let score: Int
    let total: Int
    var reason: String = ""
    let onStart: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var levelDescription: String {
        if !reason.isEmpty { return reason }
        switch level {
        case "A1": return "Начинающий\nВы делаете первые шаги — всё впереди!"
        case "A2": return "Элементарный\nЕсть базовые знания, развиваем дальше!"
        case "B1": return "Средний\nОтличный фундамент, продолжаем расти!"
        case "B2": return "Выше среднего\nВпечатляющий результат!"
        case "C1": return "Продвинутый\nВысокий уровень владения языком!"
        case "C2": return "Мастерство\nПревосходно — высший уровень!"
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground(colorScheme)
            .ignoresSafeArea()

            Circle().fill(Color.indigo.opacity(0.3)).frame(width: 280, height: 280).blur(radius: 80).offset(x: -100, y: -200)

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.indigo)
                    .padding(.bottom, 24)

                Text("Ваш уровень")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 140, height: 140)
                    Text(level)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: .indigo.opacity(0.4), radius: 20, y: 8)
                .padding(.bottom, 24)

                Text(levelDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 28)

                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Правильных ответов: \(score) из \(total)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))

                Spacer()

                Button(action: onStart) {
                    Text("Начать обучение!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .shadow(color: .indigo.opacity(0.35), radius: 10, y: 4)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    PlacementTestResultView(level: "A2", score: 7, total: 15, onStart: {})
}
