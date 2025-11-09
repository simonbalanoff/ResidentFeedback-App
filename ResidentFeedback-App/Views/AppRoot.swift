//
//  AppRoot.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct AppRoot: View {
    @EnvironmentObject var auth: AuthStore
    @Namespace private var ns
    var body: some View {
        ZStack {
            if auth.accessToken == nil {
                LoginView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity.combined(with: .scale))
            } else {
                RootTabView()
                    .matchedGeometryEffect(id: "root", in: ns)
                    .transition(.opacity)
            }
        }
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
    auth.accessToken = "token"
    return AppRoot()
        .environmentObject(auth)
        .environmentObject(APIClient(auth: auth))
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
