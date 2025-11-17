//
//  AppRoot.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct AppRoot: View {
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var api: APIClient
    @Namespace private var ns
    @State private var didAttemptRestore = false

    var body: some View {
        ZStack {
            if auth.isAuthenticated {
                RootTabView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity)
            } else {
                LoginView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .task {
            guard !didAttemptRestore else { return }
            didAttemptRestore = true

            guard auth.isAuthenticated else { return }

            do {
                try await api.loadMe()
            } catch {
                auth.clear()
            }
        }
    }
}

#Preview("Logged Out") {
    let auth = AuthStore()
    let api = APIClient(auth: auth)
    return AppRoot()
        .environmentObject(auth)
        .environmentObject(api)
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}

#Preview("Logged In") {
    let auth = AuthStore()
    auth.setTokens(access: "token", refresh: "refresh")
    auth.me = Me(id: "1", email: "a@b.com", name: "Dr. Tester", role: "admin")
    let api = APIClient(auth: auth)
    return AppRoot()
        .environmentObject(auth)
        .environmentObject(api)
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
