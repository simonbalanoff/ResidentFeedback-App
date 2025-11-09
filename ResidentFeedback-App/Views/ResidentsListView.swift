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
    @State private var hasLoaded = false
    @State private var isRefreshing = false
    @State private var error: String?
    @State private var search = ""
    @State private var selectedPGY: Int? = nil

    var filtered: [Resident] {
        residents.filter { r in
            let t = search.isEmpty || r.name.localizedCaseInsensitiveContains(search)
            let y = selectedPGY == nil || r.pgYear == selectedPGY
            return t && y
        }
    }

    var pgyYears: [Int] {
        Array(Set(residents.map { $0.pgYear })).sorted()
    }

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                                TextField("", text: $search, prompt: Text("Search residents").foregroundColor(.white.opacity(0.5)))
                                    .foregroundStyle(Theme.textPrimary)
                                    .textInputAutocapitalization(.words)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Theme.fill)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            if !pgyYears.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Chip(title: "All", selected: selectedPGY == nil) { selectedPGY = nil }
                                        ForEach(pgyYears, id: \.self) { y in
                                            Chip(title: "PGY \(y)", selected: selectedPGY == y) { selectedPGY = y }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !hasLoaded && loading {
                        ProgressView().tint(.white).padding(.top, 8)
                    } else if let e = error {
                        ErrorBanner(message: e)
                    } else if filtered.isEmpty {
                        GlassCard {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("No residents").foregroundStyle(Theme.textPrimary).font(.headline)
                                Text("Add residents or adjust filters").foregroundStyle(Theme.textSecondary).font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 10) {
                            if isRefreshing {
                                ForEach(filtered.indices, id: \.self) { _ in GlassRowSkeleton() }
                            } else {
                                ForEach(filtered) { r in ResidentRow(resident: r) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 82)
                .refreshable { await refresh() }
                .task { await initialLoad() }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    func initialLoad() async {
        loading = true
        error = nil
        do {
            residents = try await api.residents()
        } catch {
            self.error = "Failed to load residents"
        }
        loading = false
        hasLoaded = true
    }

    func refresh() async {
        isRefreshing = true
        error = nil
        do {
            residents = try await api.residents()
        } catch {
            self.error = "Failed to load residents"
        }
        isRefreshing = false
        hasLoaded = true
    }
}

private struct ResidentRow: View {
    let resident: Resident
    var body: some View {
        GlassCard {
            HStack {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.25)).frame(width: 46, height: 46)
                    Image(systemName: "person.fill").foregroundStyle(.white).font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(resident.name).foregroundStyle(Theme.textPrimary).font(.headline)
                    Text("PGY \(resident.pgYear)").foregroundStyle(Theme.textSecondary).font(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

private struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(selected ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Theme.fill.opacity(0.7) : Theme.fill)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct GlassRowSkeleton: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 23).fill(shimmer).frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 6).fill(shimmer).frame(width: 160, height: 14)
                    RoundedRectangle(cornerRadius: 6).fill(shimmer).frame(width: 80, height: 12)
                }
                Spacer()
            }
        }
        .onAppear { withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 } }
    }
    var shimmer: LinearGradient {
        LinearGradient(gradient: Gradient(stops: [
            .init(color: .white.opacity(0.18), location: phase - 0.3),
            .init(color: .white.opacity(0.32), location: phase),
            .init(color: .white.opacity(0.18), location: phase + 0.3)
        ]), startPoint: .leading, endPoint: .trailing)
    }
}
