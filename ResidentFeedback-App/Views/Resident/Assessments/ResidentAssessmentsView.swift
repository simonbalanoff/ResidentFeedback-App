//
//  ResidentAssessmentsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/17/25.
//

import SwiftUI

struct ResidentAssessmentsView: View {
    @EnvironmentObject var api: APIClient
    @EnvironmentObject var auth: AuthStore
    let resident: Resident

    @State private var assessments: [Assessment] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var hasLoaded = false
    @State private var showNewForResident = false

    var visibleAssessments: [Assessment] {
        let allForResident = assessments.filter { $0.residentId == resident.id }

        if auth.isAdmin {
            return allForResident.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        }

        guard let surgeonId = auth.currentUserId else {
            return []
        }

        return allForResident
            .filter { $0.surgeonId == surgeonId }
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        Group {
            if loading && !hasLoaded {
                VStack {
                    ProgressView()
                        .tint(Theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            } else if let e = loadError, visibleAssessments.isEmpty {
                VStack(spacing: 12) {
                    ErrorBanner(message: e)
                    Button("Retry") { Task { await initialLoad() } }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg)
            } else {
                List {
                    if visibleAssessments.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.subtext.opacity(0.6))
                            Text("No assessments for this resident yet.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.subtext)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(visibleAssessments) { assessment in
                            NavigationLink {
                                AssessmentDetailView(assessment: assessment, resident: resident)
                            } label: {
                                AssessmentRow(assessment: assessment)
                            }
                        }
                        .onDelete { indexSet in
                            let toDelete = indexSet.compactMap { index in
                                index < visibleAssessments.count ? visibleAssessments[index] : nil
                            }
                            Task {
                                await deleteAssessments(toDelete)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
                .tint(Theme.accent)
                .navigationTitle(resident.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("PGY \(resident.pgYear)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.subtext)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            EditButton()
                            Button {
                                showNewForResident = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showNewForResident) {
                    NewAssessmentWizard(preselectedResidentId: resident.id)
                }
            }
        }
        .background(Theme.bg)
        .task { await initialLoad() }
        .refreshable { await refresh() }
    }

    func initialLoad() async {
        guard !hasLoaded else { return }
        loading = true
        loadError = nil
        do {
            assessments = try await api.assessments(forResidentId: resident.id)
            hasLoaded = true
        } catch {
            loadError = "Failed to load assessments"
        }
        loading = false
    }

    func refresh() async {
        loadError = nil
        do {
            assessments = try await api.assessments(forResidentId: resident.id)
        } catch {
            loadError = "Failed to load assessments"
        }
    }

    func deleteAssessments(_ items: [Assessment]) async {
        for assessment in items {
            assessments.removeAll { $0.id == assessment.id }
            do {
                try await api.deleteAssessment(id: assessment.id)
            } catch {
            }
        }
    }
}
