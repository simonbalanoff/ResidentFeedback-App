//
//  SettingsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthStore
    @State private var showLogoutConfirm = false
    @State private var showManageResidents = false

    var isAdmin: Bool { (auth.me?.role ?? "").lowercased() == "admin" }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Theme.accent.opacity(0.25)).frame(width: 54, height: 54)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.me?.name ?? "Surgeon")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.title3.bold())
                            Text(auth.me?.email ?? "")
                                .foregroundStyle(Theme.textSecondary)
                                .font(.footnote)
                        }
                        Spacer()
                    }
                }

                if isAdmin {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Admin")
                                .foregroundStyle(Theme.textPrimary)
                                .font(.headline)
                            AdminRow(title: "Manage Residents", icon: "person.3") { showManageResidents = true }
                        }
                    }
                }

                Button {
                    showLogoutConfirm = true
                } label: {
                    Text("Log Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(Color.red)
                .background(
                    LinearGradient(colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 82)
        }
        .sheet(isPresented: $showManageResidents) { ManageResidentsView() }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { auth.clear() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct AdminRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(Theme.textPrimary)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(Theme.fill)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
