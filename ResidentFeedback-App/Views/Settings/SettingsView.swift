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
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.primary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(auth.me?.name ?? "Surgeon")
                            .font(.headline)
                            .foregroundStyle(Theme.text)

                        Text(auth.me?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(Theme.subtext)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.card)

            Section("Appearance") {
                Picker("Mode", selection: Binding(
                    get: { appearance.mode },
                    set: { appearance.set($0) }
                )) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
            }
            .listRowBackground(Theme.card)

            if isAdmin {
                Section("Admin") {
                    Button {
                        showManageResidents = true
                    } label: {
                        HStack {
                            Image(systemName: "person.3.sequence.fill")
                                .foregroundStyle(Theme.accent)
                            Text("Manage Residents")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }

            Section {
                Button(role: .destructive) {
                    showLogoutSheet = true
                } label: {
                    Text("Log Out")
                }
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
        .fullScreenCover(isPresented: $showManageResidents, onDismiss: {
            NotificationCenter.default.post(name: .residentsDidChange, object: nil)
        }) {
            NavigationStack {
                ManageResidentsView()
            }
            .tint(Theme.accent)
        }
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
                .foregroundStyle(Theme.text)

            Text("You’ll need to sign in again to continue.")
                .font(.subheadline)
                .foregroundStyle(Theme.subtext)
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
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AuthStore())
    .environmentObject(AppearanceStore())
}
