//
//  AppRoot.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct AppRoot: View {
    @EnvironmentObject var auth: AuthStore
    var body: some View {
        Group {
            if auth.accessToken == nil {
                LoginView()
            } else {
                RootTabView()
            }
        }
    }
}
