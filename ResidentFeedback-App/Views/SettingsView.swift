//
//  SettingsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let me = auth.me {
                        LabeledContent("Name", value: me.name)
                        LabeledContent("Email", value: me.email)
                        LabeledContent("Role", value: me.role)
                    }
                }
                Section {
                    Button("Log Out") { auth.clear() }.foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
