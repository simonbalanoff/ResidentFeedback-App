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
    @StateObject private var vm: AuthViewModel
    
    init() {
        let stubAuth = AuthStore()
        let stubApi = APIClient(auth: stubAuth)
        _vm = StateObject(wrappedValue: AuthViewModel(api: stubApi, auth: stubAuth))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Surgeon Feedback").font(.largeTitle).bold()
            VStack(spacing: 12) {
                TextField("Email", text: Binding(get: { vm.email }, set: { vm.email = $0 }))
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: Binding(get: { vm.password }, set: { vm.password = $0 }))
                    .textFieldStyle(.roundedBorder)
            }.padding(.horizontal)
            Button {
                Task {
                    vm.api.auth.accessToken = authStore.accessToken
                    vm.api.auth.refreshToken = authStore.refreshToken
                    do {
                        try await vm.api.login(email: vm.email, password: vm.password)
                        authStore.setTokens(access: vm.api.auth.accessToken ?? "", refresh: vm.api.auth.refreshToken ?? "")
                        authStore.me = vm.api.auth.me
                    } catch {
                        vm.error = "Login failed"
                    }
                }
            } label: {
                if vm.isLoading { ProgressView() } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            if let e = vm.error { Text(e).foregroundColor(.red) }
        }
    }
}
