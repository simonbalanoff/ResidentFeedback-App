//
//  LoginView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var api: APIClient
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var focused: Field?

    enum Field { case email, password }

    var disabled: Bool {
        email.isEmpty || password.isEmpty || isLoading
    }

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()
            VStack(spacing: 26) {
                VStack(spacing: 10) {
                    AppLogo()
                    Text("Surgeon Feedback")
                        .foregroundStyle(Theme.textPrimary)
                        .font(.largeTitle.bold())
                    Text("Sign in to continue")
                        .foregroundStyle(Theme.textSecondary)
                        .font(.subheadline)
                }
                .padding(.top, 24)

                GlassCard {
                    VStack(spacing: 14) {
                        IconField(systemImage: "envelope.fill", title: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focused, equals: .email)
                            .onSubmit { focused = .password }

                        IconField(systemImage: "lock.fill", title: "Password", text: $password, isSecure: true)
                            .submitLabel(.go)
                            .focused($focused, equals: .password)
                            .onSubmit { login() }

                        if let e = error {
                            ErrorBanner(message: e)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Button(action: login) {
                            HStack(spacing: 8) {
                                if isLoading { ProgressView().tint(.white) }
                                Text(isLoading ? "Signing In..." : "Sign In")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(disabled)
                        .opacity(disabled ? 0.6 : 1)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
        }
        .onAppear { focused = .email }
    }

    func login() {
        guard !disabled else { return }
        Task {
            isLoading = true
            error = nil
            do {
                try await api.login(email: email, password: password)
                authStore.setTokens(access: api.auth.accessToken ?? "", refresh: api.auth.refreshToken ?? "")
                authStore.me = api.auth.me
            } catch {
                self.error = "Login failed"
            }
            isLoading = false
        }
    }
}
