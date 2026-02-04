//
//  AuthView.swift
//  AdaptLingo
//
//  Created by Sergey on 03.02.2026.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isShowingSignUp = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("AdaptLingo")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Мобильное изучение иностранных языков \nс адаптивными заданиями")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("name@example.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Пароль")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        SecureField("Минимум 8 символов", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: {
                        viewModel.login()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Войти")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.isFormValid ? Color.accentColor : Color.accentColor.opacity(0.4))
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    
                    Button {
                        viewModel.forgotPassword()
                    } label: {
                        Text("Забыли пароль?")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Еще нет аккаунта?")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Button {
                        isShowingSignUp = true
                    } label: {
                        Text("Зарегистрироваться")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $isShowingSignUp) {
            SignUpView(
                initialEmail: viewModel.email,
                onSignUpSuccess: {
                    viewModel.password = ""
                    isShowingSignUp = false
                },
                onCancel: { isShowingSignUp = false }
            )
        }
    }
}

#Preview {
    AuthView()
}
