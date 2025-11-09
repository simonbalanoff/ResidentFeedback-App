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
    let startNewAssessment: () -> Void

    var filtered: [Resident] {
        residents.filter { r in
            let t = search.isEmpty || r.name.localizedCaseInsensitiveContains(search)
            let y = selectedPGY == nil || r.pgYear == selectedPGY
            return t && y
        }
        .sorted { $0.name < $1.name }
    }

    var pgyYears: [Int] {
        Array(Set(residents.map { $0.pgYear })).sorted()
    }

    var body: some View {
        Group {
            if loading { ProgressView() }
            else if let e = loadError { VStack(spacing: 12) { ErrorBanner(message: e); Button("Retry") { Task { await load() } } } }
            else {
                List {
                    ForEach(filtered) { r in
                        NavigationLink(value: r) {
                            HStack {
                                Image(systemName: "person.fill")
                                VStack(alignment: .leading) {
                                    Text(r.name)
                                    Text("PGY \(r.pgYear)").foregroundStyle(Theme.subtext).font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .navigationDestination(for: Resident.self) { r in
                    ResidentDetailView(resident: r)
                }
                .listStyle(.insetGrouped)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("All") { selectedPGY = nil }
                            ForEach(pgyYears, id: \.self) { y in
                                Button("PGY \(y)") { selectedPGY = y }
                            }
                        } label: {
                            Label(selectedPGY == nil ? "PGY" : "PGY \(selectedPGY!)", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            startNewAssessment()
                        } label: {
                            Label("New Assessment", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .navigationTitle("Residents")
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    func load() async {
        loading = true
        loadError = nil
        do { residents = try await api.residents() }
        catch { loadError = "Failed to load residents" }
        loading = false
    }
}

struct ResidentDetailView: View {
    @EnvironmentObject var api: APIClient
    @EnvironmentObject var aVM: AssessmentViewModel
    let resident: Resident
    @State private var working = false
    @State private var active = false
    @State private var name = ""
    @State private var pgy = 1
    @State private var error: String?

    var body: some View {
        Form {
            Section("Resident") {
                TextField("Name", text: $name)
                Stepper(value: $pgy, in: 1...10) { Text("PGY \(pgy)") }
                Toggle("Active", isOn: $active)
                if let e = error { Text(e).foregroundStyle(.red) }
            }
            Section {
                Button {
                    aVM.draft.residentId = resident.id
                    aVM.draft.surgeryType = ""
                    aVM.draft.note = ""
                    aVM.draft.feedback = ""
                } label: {
                    NavigationLink(destination: NewAssessmentWizard(preselectedResidentId: resident.id)) {
                        EmptyView()
                    }.opacity(0)
                }.hidden()

                Button {
                    aVM.draft = AssessmentDraft(residentId: resident.id, surgeryType: "", complexity: .Moderate, trustLevel: .DirectSupervision, note: "", feedback: "")
                    aVM.submitted = false
                } label: {
                    NavigationLink("Create Assessment", destination: NewAssessmentWizard(preselectedResidentId: resident.id))
                }
                Button(role: .none) {
                    Task { await save() }
                } label: {
                    if working { ProgressView() } else { Text("Save Changes") }
                }
            }
        }
        .navigationTitle(resident.name)
        .onAppear {
            name = resident.name
            pgy = resident.pgYear
            active = resident.active
        }
    }

    func save() async {
        working = true
        error = nil
        do { try await api.updateResident(id: resident.id, name: name, pgYear: pgy, active: active) }
        catch { }
        working = false
    }
}

#Preview("ResidentsListView") {
    NavigationStack {
        ResidentsListView(startNewAssessment: {})
    }
    .environmentObject(APIClient(auth: AuthStore()))
    .environmentObject(AssessmentViewModel())
}

#Preview("ResidentDetailView") {
    NavigationStack {
        ResidentDetailView(resident: Resident(id: "1", name: "Jane Resident", pgYear: 3, active: true))
    }
    .environmentObject(APIClient(auth: AuthStore()))
    .environmentObject(AssessmentViewModel())
}
