//
//  SettingsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var appearance: AppearanceStore
    @State private var showLogoutConfirm = false
    @State private var showManageResidents = false
    var isAdmin: Bool { (auth.me?.role ?? "").lowercased() == "admin" }

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                    VStack(alignment: .leading) {
                        Text(auth.me?.name ?? "Surgeon")
                        Text(auth.me?.email ?? "").foregroundStyle(.secondary).font(.subheadline)
                    }
                }
            }
            Section("Appearance") {
                Picker("Mode", selection: Binding(get: { appearance.mode }, set: { appearance.set($0) })) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
            }
            if isAdmin {
                Section("Admin") {
                    Button {
                        showManageResidents = true
                    } label: {
                        Label("Manage Residents", systemImage: "person.3")
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Text("Log Out")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showManageResidents) { ManageResidentsView() }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { auth.clear() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AuthStore())
    .environmentObject(AppearanceStore())
}
