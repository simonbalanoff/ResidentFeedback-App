//
//  AuthViewModel.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation
internal import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var loadError: String?
    let api: APIClient
    let auth: AuthStore
    init(api: APIClient, auth: AuthStore) {
        self.api = api
        self.auth = auth
    }
    func login() async {
        isLoading = true
        loadError = nil
        do { try await api.login(email: email, password: password) } catch { loadError = "Login failed" }
        isLoading = false
    }
    func register() async {
        isLoading = true
        loadError = nil
        do { try await api.register(name: name, email: email, password: password) } catch { loadError = "Registration failed" }
        isLoading = false
    }
    func logout() {
        auth.clear()
    }
}
