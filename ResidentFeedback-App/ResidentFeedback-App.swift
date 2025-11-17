//
//  ResidentFeedback_App.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

@main
struct ResidentFeedback_AppApp: App {
    @StateObject private var authStore: AuthStore
    @StateObject private var apiClient: APIClient
    @StateObject private var assessmentVM = AssessmentViewModel()
    @StateObject private var appearance = AppearanceStore()

    init() {
        let auth = AuthStore()
        _authStore = StateObject(wrappedValue: auth)
        _apiClient = StateObject(wrappedValue: APIClient(auth: auth))
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environmentObject(authStore)
                .environmentObject(apiClient)
                .environmentObject(assessmentVM)
                .environmentObject(appearance)
                .preferredColorScheme(appearance.preferredColorScheme)
        }
    }
}

#Preview("AppRoot") {
    let auth = AuthStore()
    let api = APIClient(auth: auth)
    return AppRoot()
        .environmentObject(auth)
        .environmentObject(api)
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
