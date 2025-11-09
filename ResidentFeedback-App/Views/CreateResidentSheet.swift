//
//  CreateResidentSheet.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct CreateResidentSheet: View {
    @EnvironmentObject var api: APIClient
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var pgy = 1
    @State private var active = true
    @State private var isSubmitting = false
    @State private var loadError: String?
    let onCreated: (Resident) -> Void

    var disabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Form {
                    Section("Resident") {
                        TextField("Full name", text: $name)
                        Stepper(value: $pgy, in: 1...10) { Text("PGY \(pgy)") }
                        Toggle("Active", isOn: $active)
                    }
                    if let e = loadError {
                        Section { Text(e).foregroundStyle(.red) }
                    }
                }
                Button {
                    Task { await submit() }
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting { ProgressView() }
                        Text(isSubmitting ? "Creating..." : "Create Resident")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(disabled)
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .navigationTitle("New Resident")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    func submit() async {
        guard !disabled else { return }
        isSubmitting = true
        loadError = nil
        do {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let id = try await api.createResident(name: trimmed, pgYear: pgy, active: active)
            let created = Resident(id: id, name: trimmed, pgYear: pgy, active: active)
            onCreated(created)
            dismiss()
        } catch {
            loadError = "Failed to create resident"
        }
        isSubmitting = false
    }
}

#Preview {
    NavigationStack {
        CreateResidentSheet { _ in }
    }
    .environmentObject(APIClient(auth: AuthStore()))
}
