//
//  ResidentReviewsView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/16/25.
//

import SwiftUI

import SwiftUI

struct ResidentReviewsView: View {
    @EnvironmentObject var api: APIClient
    @Environment(\.dismiss) var dismiss

    let resident: Resident

    @State private var reviews: [Assessment] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var filter: ReviewFilter = .all

    enum ReviewFilter: String, CaseIterable, Identifiable {
        case all
        case recent
        case highTrust

        var id: Self { self }

        var title: String {
            switch self {
            case .all: return "All"
            case .recent: return "Recent"
            case .highTrust: return "High Trust"
            }
        }
    }

    var filteredReviews: [Assessment] {
        switch filter {
        case .all:
            return reviews
        case .recent:
            return reviews.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .highTrust:
            return reviews.filter { $0.trustLevel == .PracticeReady || $0.trustLevel == .IndirectSupervision }
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                content
            }
        }
        .task { await loadReviews() }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

                VStack(spacing: 2) {
                    Text("Assessments")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text(resident.name)
                        .font(.subheadline)
                        .foregroundStyle(Theme.subtext)
                }

                Spacer()

                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(ReviewFilter.allCases) { f in
                            Text(f.title).tag(f)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filter.title)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.card)
                    .clipShape(Capsule())
                }
                .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 6)
    }

    @ViewBuilder
    var content: some View {
        if loading && reviews.isEmpty {
            VStack {
                Spacer()
                ProgressView()
                    .tint(Theme.accent)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let e = loadError, reviews.isEmpty {
            VStack(spacing: 14) {
                ErrorBanner(message: e)
                Button {
                    Task { await loadReviews() }
                } label: {
                    Text("Retry")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredReviews.isEmpty {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.subtext)
                Text("No reviews yet")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text("Once feedback is submitted for this resident, it will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredReviews) { review in
                        ReviewCard(review: review)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    func loadReviews() async {
        loading = true
        loadError = nil
        do {
            reviews = try await api.assessments(forResidentId: resident.id)
        } catch {
            loadError = "Failed to load reviews"
        }
        loading = false
    }
}


struct ReviewCard: View {
    let review: Assessment

    var dateString: String {
        guard let date = review.createdAt else { return "Date unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(dateString)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                HStack(spacing: 6) {
                    if let c = review.complexity {
                        Pill(text: c.rawValue, systemImage: "chart.bar.fill", highlighted: true)
                    }
                    if let t = review.trustLevel {
                        Pill(text: t.rawValue, systemImage: "star.fill", highlighted: true)
                    }
                }
            }

            if !review.surgeryType.isEmpty {
                Text(review.surgeryType)
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtext)
            }

            if !review.feedback.isEmpty {
                Text(review.feedback)
                    .font(.body)
                    .foregroundStyle(Theme.text)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
