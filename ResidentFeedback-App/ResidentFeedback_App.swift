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
    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environmentObject(auth)
                .environmentObject(APIClient(auth: auth))
                .environmentObject(AssessmentViewModel())
        }
    }
}
