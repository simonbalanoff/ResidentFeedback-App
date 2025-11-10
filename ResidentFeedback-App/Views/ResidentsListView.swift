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
                let t = search.isEmpty || r.name.localizedCaseInsensitiveContains(search)
                let y = selectedPGY == nil || r.pgYear == selectedPGY
                return t && y
            }
            .sorted { $0.name < $1.name }
    }

    var pgyYears: [Int] {
        Array(Set(residents.filter { $0.active }.map { $0.pgYear })).sorted()
    }

    var body: some View {
        Group {
            if loading && residents.isEmpty {
                ProgressView()
            } else if let e = loadError, residents.isEmpty {
                VStack(spacing: 12) {
                    ErrorBanner(message: e)
                    Button("Retry") { Task { await initialLoad() } }
                }
            } else {
                List {
                    ForEach(filtered) { r in
                        HStack {
                            Image(systemName: "person.fill")
                            VStack(alignment: .leading) {
                                Text(r.name)
                                Text("PGY \(r.pgYear)").foregroundStyle(.secondary).font(.subheadline)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { launchForResident = r }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                launchForResident = r
                            } label: {
                                Label("Assess", systemImage: "plus.circle")
                            }
                            .tint(.accentColor)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
                .navigationTitle("Residents")
                .fullScreenCover(item: $launchForResident) { res in
                    NewAssessmentWizard(preselectedResidentId: res.id)
                }
            }
        }
        .task { await initialLoad() }
        .refreshable { await refresh() }
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
