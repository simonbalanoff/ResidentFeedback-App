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
    @State private var loadError: String?
    @FocusState private var focused: Field?

    enum Field { case email, password }

    var disabled: Bool { email.isEmpty || password.isEmpty || isLoading }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 28) {
                    Spacer(minLength: 60)

                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.18))
                                .frame(width: 88, height: 88)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 14, y: 8)
                            Image(systemName: "stethoscope")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }

                        Text("Surgeon Feedback")
                            .font(.largeTitle.weight(.semibold))
                            .padding(.top, 4)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        IconField(systemImage: "envelope.fill", title: "Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.next)
                            .focused($focused, equals: .email)
                            .onSubmit { focused = .password }

                        IconField(systemImage: "lock.fill", title: "Password", text: $password, isSecure: true)
                            .submitLabel(.go)
                            .focused($focused, equals: .password)
                            .onSubmit { login() }

                        Button(action: login) {
                            HStack(spacing: 8) {
                                if isLoading { ProgressView() }
                                Text(isLoading ? "Signing In..." : "Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(disabled)
                        .opacity(disabled ? 0.6 : 1)
                        .padding(.top, 4)
                        
                        if let e = loadError {
                            ErrorBanner(message: e)
                                .transition(.opacity)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)

                    Spacer()

                    Text("By continuing you agree to the terms and privacy policy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal)
            }
        }
        .onAppear { focused = .email }
    }

    func login() {
        guard !disabled else { return }
        Task {
            isLoading = true
            loadError = nil
            do {
                try await api.login(email: email, password: password)
                authStore.setTokens(
                    access: api.auth.accessToken ?? "",
                    refresh: api.auth.refreshToken ?? ""
                )
                authStore.me = api.auth.me
            } catch {
                loadError = "Login failed"
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
        .environmentObject(APIClient(auth: AuthStore()))
}
