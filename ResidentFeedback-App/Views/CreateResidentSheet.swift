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
    @State private var error: String?
    let onCreated: (Resident) -> Void

    var disabled: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill").foregroundStyle(Theme.textSecondary)
                                TextField("", text: $name, prompt: Text("Full name").foregroundColor(.white.opacity(0.5)))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Theme.fill)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack {
                                Text("PGY").foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Stepper(value: $pgy, in: 1...10) {
                                    Text("\(pgy)").foregroundStyle(Theme.textPrimary)
                                }
                                .labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Theme.fill)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack {
                                Text("Active").foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Toggle("", isOn: $active).labelsHidden()
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Theme.fill)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            if let e = error { ErrorBanner(message: e) }
                        }
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting { ProgressView().tint(.white) }
                            Text(isSubmitting ? "Creating..." : "Create Resident")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(disabled)

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
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
        error = nil
        do {
            let id = try await api.createResident(name: name.trimmingCharacters(in: .whitespacesAndNewlines), pgYear: pgy, active: active)
            let created = Resident(id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), pgYear: pgy, active: active)
            onCreated(created)
            dismiss()
        } catch {
            self.error = "Failed to create resident"
        }
        isSubmitting = false
    }
}
