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
    @State private var iconPulsing = false

    enum Field { case email, password }

    var disabled: Bool { email.isEmpty || password.isEmpty || isLoading }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.primary
                    .ignoresSafeArea()

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .scaleEffect(1.4)
                    .blur(radius: 120)
                    .offset(x: -120, y: -240)

                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 94, height: 94)
                                .shadow(color: Color.black.opacity(0.25), radius: 20, y: 10)

                            Circle()
                                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                                .frame(width: 94, height: 94)
                                .shadow(color: Color.black.opacity(0.2), radius: 14, y: 6)

                            Image(systemName: "stethoscope")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
                                .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
                        }
                        .padding(.top, 50)

                        VStack(spacing: 4) {
                            Text("Feedback Portal")
                                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                                .kerning(0.5)

                            Text("Sign in to access your account")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        .padding(.bottom, 30)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: 240)
                    .padding(.horizontal, 32)

                    VStack(spacing: 18) {
                        VStack(spacing: 14) {
                            IconField(systemImage: "envelope.fill", title: "Work Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .textContentType(.emailAddress)
                                .submitLabel(.next)
                                .focused($focused, equals: .email)
                                .onSubmit { focused = .password }

                            IconField(systemImage: "lock.fill", title: "Password", text: $password, isSecure: true)
                                .textContentType(.password)
                                .submitLabel(.go)
                                .focused($focused, equals: .password)
                                .onSubmit { login() }
                        }

                        Button(action: login) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                }
                                Text(isLoading ? "Signing In..." : "Sign In")
                                    .font(.headline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(disabled)
                        .opacity(disabled ? 0.6 : 1)

                        if BiometricAuth.isAvailable,
                           let savedEmail = Keychain.get("savedEmail"),
                           let savedPassword = Keychain.get("savedPassword") {
                            Button {
                                Task {
                                    await biometricLogin(savedEmail: savedEmail, savedPassword: savedPassword)
                                }
                            } label: {
                                Label("Sign In with Face ID", systemImage: "faceid")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                        if let e = loadError {
                            ErrorBanner(message: e)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 24)
                    .background(
                        Theme.bg,
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 30, y: 20)
                    .padding(.horizontal)
                    .frame(maxWidth: 460)

                    Spacer()

                    Text("By continuing you agree to the terms and privacy policy.")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 18)
                }
            }
        }
        .onAppear {
            focused = .email
            iconPulsing = true
        }
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
                Keychain.set(email, key: "savedEmail")
                Keychain.set(password, key: "savedPassword")
            } catch {
                loadError = "Login failed"
            }
            isLoading = false
        }
    }

    func biometricLogin(savedEmail: String, savedPassword: String) async {
        let ok = await BiometricAuth.authenticate(reason: "Sign in to your account")
        guard ok else { return }
        isLoading = true
        loadError = nil
        do {
            try await api.login(email: savedEmail, password: savedPassword)
            authStore.setTokens(
                access: api.auth.accessToken ?? "",
                refresh: api.auth.refreshToken ?? ""
            )
            authStore.me = api.auth.me
        } catch {
            loadError = "Biometric login failed"
        }
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore())
        .environmentObject(APIClient(auth: AuthStore()))
}
