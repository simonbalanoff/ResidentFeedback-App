//
//  ResidentFeedback_App.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

@main
struct ResidentFeedback_AppApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var appearance = AppearanceStore()
    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environmentObject(auth)
                .environmentObject(APIClient(auth: auth))
                .environmentObject(AssessmentViewModel())
                .environmentObject(appearance)
                .preferredColorScheme(appearance.preferredColorScheme)
        }
    }
}

#Preview {
    AppRoot()
        .environmentObject(AuthStore())
        .environmentObject(APIClient(auth: AuthStore()))
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
