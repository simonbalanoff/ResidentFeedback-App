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
    var objectWillChange = PassthroughSubject<AuthViewModel, Never>()
    
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var error: String?
    
    let api: APIClient
    let auth: AuthStore
    init(api: APIClient, auth: AuthStore) {
        self.api = api
        self.auth = auth
    }
    
    func login() async {
        isLoading = true
        error = nil
        do {
            try await api.login(email: email, password: password)
        } catch {
            self.error = "Login failed"
        }
        isLoading = false
    }
    
    func register() async {
        isLoading = true
        error = nil
        do {
            try await api.register(name: name, email: email, password: password)
        } catch {
            self.error = "Registration failed"
        }
        isLoading = false
    }
    
    func logout() {
        auth.clear()
    }
}
