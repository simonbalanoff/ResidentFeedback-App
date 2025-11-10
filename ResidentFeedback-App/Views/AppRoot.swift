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
            if auth.accessToken == nil || auth.me == nil {
                LoginView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity.combined(with: .scale))
            } else {
                RootTabView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity)
            }
        }
        .task {
            guard !didAttemptRestore else { return }
            didAttemptRestore = true
            if auth.accessToken != nil, auth.me == nil {
                do {
                    try await api.loadMe()
                } catch {
                    auth.clear()
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.2), value: auth.accessToken != nil && auth.me != nil)
    }
}

#Preview("Logged Out") {
    AppRoot()
        .environmentObject(AuthStore())
        .environmentObject(APIClient(auth: AuthStore()))
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}

#Preview("Logged In") {
    let auth = AuthStore()
    auth.setTokens(access: "token", refresh: "refresh")
    auth.me = Me(id: "1", email: "a@b.com", name: "Dr. Tester", role: "admin")
    return AppRoot()
        .environmentObject(auth)
        .environmentObject(APIClient(auth: auth))
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
