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
    @State private var workingIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Group {
                if loading { ProgressView() }
                else if let e = loadError { VStack(spacing: 12) { ErrorBanner(message: e); Button("Retry") { Task { await reload() } } } }
                else {
                    List {
                        ForEach(residents) { r in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(r.name)
                                    Text("PGY \(r.pgYear)").foregroundStyle(.secondary).font(.subheadline)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(get: { r.active }, set: { val in
                                    Task { await setActive(r.id, val) }
                                }))
                                .labelsHidden()
                                .disabled(workingIds.contains(r.id))
                            }
                        }
                        .onDelete { idx in
                            let ids = idx.map { residents[$0].id }
                            Task { await deleteMany(ids) }
                        }
                    }
                    .listStyle(.insetGrouped)
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
        do { residents = try await api.residents() }
        catch { loadError = "Failed to load residents" }
        loading = false
    }

    func setActive(_ id: String, _ value: Bool) async {
        workingIds.insert(id)
        defer { workingIds.remove(id) }
        do {
            try await api.updateResident(id: id, active: value)
            if let i = residents.firstIndex(where: { $0.id == id }) {
                var r = residents[i]
                r = Resident(id: r.id, name: r.name, pgYear: r.pgYear, active: value)
                residents[i] = r
            }
        } catch {}
    }

    func deleteMany(_ ids: [String]) async {
        for id in ids {
            do { try await api.deleteResident(id: id) } catch {}
        }
        await reload()
    }
}

#Preview {
    ManageResidentsView()
        .environmentObject(APIClient(auth: AuthStore()))
}
