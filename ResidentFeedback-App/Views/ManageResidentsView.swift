//
//  ManageResidentsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct ManageResidentsView: View {
    @EnvironmentObject var api: APIClient
    @Environment(\.dismiss) var dismiss
    @State private var residents: [Resident] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        if loading {
                            ProgressView().tint(.white).padding(.top, 8)
                        } else if let e = loadError {
                            ErrorBanner(message: e)
                        } else if residents.isEmpty {
                            GlassCard {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 34, weight: .semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                    Text("No residents yet").foregroundStyle(Theme.textPrimary).font(.headline)
                                    Text("Tap New to add one").foregroundStyle(Theme.textSecondary).font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            ForEach(residents) { r in
                                GlassCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(r.name).foregroundStyle(Theme.textPrimary).font(.headline)
                                            Text("PGY \(r.pgYear)").foregroundStyle(Theme.textSecondary).font(.subheadline)
                                        }
                                        Spacer()
                                        Toggle("", isOn: .constant(r.active))
                                            .labelsHidden()
                                            .disabled(true)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 18)
                }
            }
            .navigationTitle("Manage Residents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("New") { showCreate = true } }
            }
            .task { await reload() }
            .sheet(isPresented: $showCreate) {
                CreateResidentSheet { created in
                    showCreate = false
                    residents.insert(created, at: 0)
                }
            }
        }
    }

    func reload() async {
        loading = true
        loadError = nil
        do {
            residents = try await api.residents()
        } catch {
            loadError = "Failed to load residents"
        }
        loading = false
    }
}

