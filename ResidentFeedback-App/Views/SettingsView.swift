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
    @State private var showLogoutSheet = false
    @State private var showManageResidents = false

    var isAdmin: Bool { (auth.me?.role ?? "").lowercased() == "admin" }

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                    VStack(alignment: .leading) {
                        Text(auth.me?.name ?? "Surgeon")
                        Text(auth.me?.email ?? "")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
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
                        Text("Manage Residents")
                    }
                }
            }
            Section {
                Button(role: .destructive) {
                    showLogoutSheet = true
                } label: {
                    Text("Log Out")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showManageResidents, onDismiss: {
            NotificationCenter.default.post(name: .residentsDidChange, object: nil)
        }) { ManageResidentsView() }
        .sheet(isPresented: $showLogoutSheet) {
            LogoutSheet {
                auth.clear()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct LogoutSheet: View {
    let onConfirm: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.red)
                .padding(.top, 12)
            Text("Sign out?")
                .font(.title2.weight(.semibold))
            Text("You’ll need to sign in again to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Log Out")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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
