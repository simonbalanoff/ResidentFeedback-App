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
    @State private var search = ""

    var filteredResidents: [Resident] {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return residents
        }
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return residents.filter { $0.name.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    Group {
                        if loading && residents.isEmpty {
                            VStack {
                                ProgressView()
                                    .tint(Theme.accent)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let e = loadError, residents.isEmpty {
                            VStack(spacing: 12) {
                                ErrorBanner(message: e)
                                Button("Retry") {
                                    Task { await reload() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.accent)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredResidents) { r in
                                    NavigationLink(value: r) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Theme.primary.opacity(0.1))
                                                    .frame(width: 34, height: 34)
                                                Text(initials(for: r.name))
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(Theme.primary)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(r.name)
                                                    .font(.headline)
                                                    .foregroundStyle(Theme.text)
                                                HStack(spacing: 8) {
                                                    Text("PGY \(r.pgYear)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(Theme.subtext)
                                                    if !r.active {
                                                        Text("Inactive")
                                                            .font(.caption.weight(.semibold))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Theme.card)
                                                            .foregroundStyle(.red)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Theme.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Theme.sep.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .task { await reload() }
            .sheet(isPresented: $showCreate) {
                CreateResidentSheet { created in
                    showCreate = false
                    residents.insert(created, at: 0)
                    NotificationCenter.default.post(name: .residentsDidChange, object: nil)
                }
            }
            .navigationDestination(for: Resident.self) { res in
                EditResidentSheet(
                    resident: res,
                    onUpdated: { updated in
                        if let i = residents.firstIndex(where: { $0.id == updated.id }) {
                            residents[i] = updated
                        }
                        NotificationCenter.default.post(name: .residentsDidChange, object: nil)
                    },
                    onDeleted: { id in
                        residents.removeAll { $0.id == id }
                        NotificationCenter.default.post(name: .residentsDidChange, object: nil)
                    }
                )
            }
            .navigationBarHidden(true)
        }
    }

    var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .foregroundStyle(Theme.accent)

                Spacer()

                Text("Manage Residents")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    showCreate = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .accessibilityLabel("New Resident")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)

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

    func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            let first = parts.first?.first.map(String.init) ?? ""
            let last = parts.last?.first.map(String.init) ?? ""
            return (first + last).uppercased()
        } else if let first = parts.first?.first {
            return String(first).uppercased()
        } else {
            return "R"
        }
    }
}

#Preview {
    ManageResidentsView()
        .environmentObject(APIClient(auth: AuthStore()))
}
