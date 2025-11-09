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
        .animation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.2), value: auth.accessToken != nil)
    }
}
