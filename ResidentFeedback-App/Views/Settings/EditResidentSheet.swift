//
//  EditResidentSheet.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/16/25.
//

import SwiftUI

struct EditResidentSheet: View {
    @EnvironmentObject var api: APIClient
    @Environment(\.dismiss) var dismiss

    let resident: Resident
    let onUpdated: (Resident) -> Void
    let onDeleted: (String) -> Void

    @State private var name: String
    @State private var pgYear: Int
    @State private var isActive: Bool
    @State private var isSaving = false
    @State private var showDeleteConfirm = false
    @State private var showDiscardConfirm = false
    @State private var loadError: String?

    init(resident: Resident, onUpdated: @escaping (Resident) -> Void, onDeleted: @escaping (String) -> Void) {
        self.resident = resident
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _name = State(initialValue: resident.name)
        _pgYear = State(initialValue: resident.pgYear)
        _isActive = State(initialValue: resident.active)
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasChanges: Bool {
        trimmedName != resident.name ||
        pgYear != resident.pgYear ||
        isActive != resident.active
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Form {
                    if let err = loadError {
                        Section {
                            ErrorBanner(message: err)
                        }
                        .listRowBackground(Theme.card)
                    }

                    Section("Resident") {
                        TextField("Name", text: $name)
                        Picker("PGY Year", selection: $pgYear) {
                            ForEach(1...7, id: \.self) { year in
                                Text("PGY \(year)").tag(year)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)

                    Section("Status") {
                        Toggle("Active", isOn: $isActive)
                            .tint(Theme.accent)
                    }
                    .listRowBackground(Theme.card)

                    Section("Reviews") {
                        NavigationLink {
                            ResidentReviewsView(resident: resident)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundStyle(Theme.accent)
                                Text("View Reviews")
                            }
                        }
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete Resident")
                        }
                    }
                    .listRowBackground(Theme.card)
                }
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
            }
        }
        .confirmationDialog(
            "Delete Resident?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await delete() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Discard changes?",
            isPresented: $showDiscardConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    handleClose()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .foregroundStyle(Theme.accent)

                Spacer()

                Text("Edit Resident")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                            .frame(width: 44, height: 30)
                    } else {
                        Text("Save")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 30)
                            .padding(5)
                    }
                }
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .opacity(isSaving || trimmedName.isEmpty ? 0.6 : 1)
                .disabled(isSaving || trimmedName.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .padding(.bottom, 6)
    }

    func handleClose() {
        if hasChanges {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        loadError = nil
        do {
            if trimmedName != resident.name {
                try await api.updateResident(id: resident.id, name: trimmedName)
            }
            if pgYear != resident.pgYear {
                try await api.updateResident(id: resident.id, pgYear: pgYear)
            }
            if isActive != resident.active {
                try await api.updateResident(id: resident.id, active: isActive)
            }
            let updated = Resident(id: resident.id, name: trimmedName, pgYear: pgYear, active: isActive)
            onUpdated(updated)
            dismiss()
        } catch {
            loadError = "Failed to save changes"
        }
        isSaving = false
    }

    func delete() async {
        do {
            try await api.deleteResident(id: resident.id)
            onDeleted(resident.id)
            dismiss()
        } catch {
            loadError = "Failed to delete resident"
        }
    }
}

