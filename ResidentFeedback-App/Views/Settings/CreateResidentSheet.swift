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

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var disabled: Bool {
        trimmedName.isEmpty || isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    Form {
                        if let e = loadError {
                            Section {
                                ErrorBanner(message: e)
                            }
                            .listRowBackground(Theme.card)
                        }

                        Section("Resident") {
                            TextField("Full name", text: $name)
                            Stepper(value: $pgy, in: 1...10) {
                                Text("PGY \(pgy)")
                            }
                            Toggle("Active", isOn: $active)
                                .tint(Theme.accent)
                        }
                        .listRowBackground(Theme.card)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    var header: some View {
        VStack(spacing: 8) {
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

                Text("New Resident")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Spacer()

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                            .frame(width: 60, height: 30)
                    } else {
                        Text("Create")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 60, height: 30)
                            .padding(5)
                    }
                }
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .opacity(disabled ? 0.6 : 1)
                .disabled(disabled)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .padding(.bottom, 6)
    }

    func submit() async {
        guard !disabled else { return }
        isSubmitting = true
        loadError = nil
        do {
            let id = try await api.createResident(name: trimmedName, pgYear: pgy, active: active)
            let created = Resident(id: id, name: trimmedName, pgYear: pgy, active: active)
            onCreated(created)
            dismiss()
        } catch {
            loadError = "Failed to create resident"
        }
        isSubmitting = false
    }
}

#Preview {
    CreateResidentSheet { _ in }
        .environmentObject(APIClient(auth: AuthStore()))
}
