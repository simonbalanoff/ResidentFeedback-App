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
                if loading && residents.isEmpty { ProgressView() }
                else if let e = loadError, residents.isEmpty {
                    VStack(spacing: 12) { ErrorBanner(message: e); Button("Retry") { Task { await reload() } } }
                } else {
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
                            .contextMenu {
                                Button("Rename") {
                                    Task {
                                        await rename(r)
                                    }
                                }
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
                    NotificationCenter.default.post(name: .residentsDidChange, object: nil)
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
                let r = residents[i]
                residents[i] = Resident(id: r.id, name: r.name, pgYear: r.pgYear, active: value)
            }
            NotificationCenter.default.post(name: .residentsDidChange, object: nil)
        } catch {}
    }

    func deleteMany(_ ids: [String]) async {
        for id in ids {
            do { try await api.deleteResident(id: id) } catch {}
        }
        await reload()
        NotificationCenter.default.post(name: .residentsDidChange, object: nil)
    }

    func rename(_ r: Resident) async {
        let new = await promptRename(defaultText: r.name)
        guard let new, !new.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            try await api.updateResident(id: r.id, name: new)
            if let i = residents.firstIndex(where: { $0.id == r.id }) {
                let cur = residents[i]
                residents[i] = Resident(id: cur.id, name: new, pgYear: cur.pgYear, active: cur.active)
            }
            NotificationCenter.default.post(name: .residentsDidChange, object: nil)
        } catch {}
    }

    @MainActor
    func promptRename(defaultText: String) async -> String? {
        await withCheckedContinuation { cont in
            var text = defaultText
            let alert = UIAlertController(title: "Rename Resident", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in cont.resume(returning: nil) })
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                text = alert.textFields?.first?.text ?? defaultText
                cont.resume(returning: text)
            })
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.keyWindow?.rootViewController?
                .present(alert, animated: true)
        }
    }
}

#Preview {
    ManageResidentsView()
        .environmentObject(APIClient(auth: AuthStore()))
}
