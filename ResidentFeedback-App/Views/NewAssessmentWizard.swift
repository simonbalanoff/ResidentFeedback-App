//
//  NewAssessmentWizard.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct NewAssessmentWizard: View {
    @EnvironmentObject var api: APIClient
    @EnvironmentObject var aVM: AssessmentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var step = 0
    @State private var residents: [Resident] = []
    @State private var loadError: String?
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $step) {
                    SelectResidentStep(selectedId: $aVM.draft.residentId, residents: residents)
                        .tag(0)
                    SurgeryTypeStep(surgeryType: $aVM.draft.surgeryType)
                        .tag(1)
                    ComplexityStep(selection: $aVM.draft.complexity)
                        .tag(2)
                    TrustStep(selection: $aVM.draft.trustLevel)
                        .tag(3)
                    NotesStep(title: "Note", text: $aVM.draft.note)
                        .tag(4)
                    NotesStep(title: "Feedback", text: $aVM.draft.feedback)
                        .tag(5)
                    ReviewStep(submit: submit, draft: aVM.draft)
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .navigationTitle("New Assessment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task {
                do {
                    residents = try await api.residents()
                } catch {
                    loadError = "Failed to load residents"
                }
            }
        }
    }
    func submit() {
        Task {
            aVM.isSubmitting = true
            do { try await api.createAssessment(aVM.draft); aVM.submitted = true; aVM.reset(); dismiss() }
            catch { aVM.error = "Submit failed" }
            aVM.isSubmitting = false
        }
    }
}

struct SelectResidentStep: View {
    @Binding var selectedId: String
    let residents: [Resident]
    var body: some View {
        VStack {
            Text("Select Resident").font(.title2).bold()
            if residents.isEmpty { ProgressView().padding() }
            else {
                List(residents, id: \.id) { r in
                    HStack {
                        Text(r.name)
                        Spacer()
                        if selectedId == r.id { Image(systemName: "checkmark.circle.fill") }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedId = r.id }
                }
            }
            Spacer()
        }.padding()
    }
}

struct SurgeryTypeStep: View {
    @Binding var surgeryType: String
    var body: some View {
        Form {
            Section("Surgery Type") {
                TextField("e.g. Lumpectomy", text: $surgeryType)
            }
        }
    }
}

struct ComplexityStep: View {
    @Binding var selection: CaseComplexity
    var body: some View {
        Form {
            Section("Case Complexity") {
                Picker("Complexity", selection: $selection) {
                    ForEach(CaseComplexity.allCases) { c in Text(c.rawValue).tag(c) }
                }.pickerStyle(.segmented)
            }
        }
    }
}

struct TrustStep: View {
    @Binding var selection: TrustLevel
    var body: some View {
        Form {
            Section("Trust Level") {
                Picker("Trust", selection: $selection) {
                    ForEach(TrustLevel.allCases) { t in Text(t.rawValue).tag(t) }
                }
            }
        }
    }
}

struct NotesStep: View {
    let title: String
    @Binding var text: String
    var body: some View {
        Form { Section(title) { TextEditor(text: $text).frame(minHeight: 160) } }
    }
}

struct ReviewStep: View {
    let submit: () -> Void
    let draft: AssessmentDraft
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review").font(.title2).bold()
            Group {
                HStack { Text("Resident"); Spacer(); Text(draft.residentId.isEmpty ? "Not selected" : draft.residentId) }
                HStack { Text("Surgery Type"); Spacer(); Text(draft.surgeryType.isEmpty ? "Not set" : draft.surgeryType) }
                HStack { Text("Complexity"); Spacer(); Text(draft.complexity.rawValue) }
                HStack { Text("Trust"); Spacer(); Text(draft.trustLevel.rawValue) }
            }
            VStack(alignment: .leading) { Text("Note").bold(); Text(draft.note.isEmpty ? "None" : draft.note) }
            VStack(alignment: .leading) { Text("Feedback").bold(); Text(draft.feedback.isEmpty ? "None" : draft.feedback) }
            Button(action: submit) { Text("Submit Assessment").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }
}
