//
//  ResidentsListView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct ResidentsListView: View {
    @EnvironmentObject var api: APIClient
    @State private var residents: [Resident] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var search = ""
    @State private var selectedPGY: Int? = nil
    @State private var hasLoaded = false
    @State private var launchForResident: Resident?
    let startNewAssessment: () -> Void

    var filtered: [Resident] {
        residents
            .filter { $0.active }
            .filter { r in
                let t = search.trimmingCharacters(in: .whitespacesAndNewlines)
                let matchesSearch = t.isEmpty || r.name.localizedCaseInsensitiveContains(t)
                let matchesPGY = selectedPGY == nil || r.pgYear == selectedPGY
                return matchesSearch && matchesPGY
            }
            .sorted { $0.name < $1.name }
    }

    var pgyYears: [Int] {
        Array(Set(residents.filter { $0.active }.map { $0.pgYear })).sorted()
    }

    var body: some View {
        Group {
            if loading && residents.isEmpty {
                VStack {
                    ProgressView()
                        .tint(Theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            } else if let e = loadError, residents.isEmpty {
                VStack(spacing: 12) {
                    ErrorBanner(message: e)
                    Button("Retry") { Task { await initialLoad() } }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            } else {
                VStack(spacing: 0) {
                    searchBar

                    List {
                        ForEach(filtered) { r in
                            NavigationLink {
                                ResidentAssessmentsView(resident: r)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.primary.opacity(0.08))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(Theme.primary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.name)
                                            .foregroundStyle(Theme.text)
                                        Text("PGY \(r.pgYear)")
                                            .foregroundStyle(Theme.subtext)
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    launchForResident = r
                                } label: {
                                    Label("Assess", systemImage: "plus.circle")
                                }
                                .tint(Theme.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg)
                    .tint(Theme.accent)
                }
                .background(Theme.bg)
                .navigationTitle("Residents")
                .fullScreenCover(item: $launchForResident) { res in
                    NewAssessmentWizard(preselectedResidentId: res.id)
                }
            }
        }
        .task { await initialLoad() }
        .refreshable { await refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .residentsDidChange)) { _ in
            Task { await refresh() }
        }
    }

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.subtext)
            TextField("Search residents", text: $search)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    func initialLoad() async {
        guard !hasLoaded else { return }
        loading = true
        loadError = nil
        do {
            residents = try await api.residents()
            hasLoaded = true
        } catch {
            loadError = "Failed to load residents"
        }
        loading = false
    }

    func refresh() async {
        loadError = nil
        do { residents = try await api.residents() }
        catch { loadError = "Failed to load residents" }
    }
}

extension Notification.Name {
    static let residentsDidChange = Notification.Name("residentsDidChange")
}

#Preview("ResidentsListView") {
    NavigationStack {
        ResidentsListView(startNewAssessment: {})
    }
    .environmentObject(APIClient(auth: AuthStore()))
    .environmentObject(AssessmentViewModel())
}
