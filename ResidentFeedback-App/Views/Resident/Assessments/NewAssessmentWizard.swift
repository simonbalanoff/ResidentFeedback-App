//
//  NewAssessmentWizard.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI
import UIKit

private extension View {
    func erased() -> AnyView { AnyView(self) }
}

struct NewAssessmentWizard: View {
    @EnvironmentObject var api: APIClient
    @EnvironmentObject var aVM: AssessmentViewModel
    @Environment(\.dismiss) var dismiss

    @State private var step = 0
    @State private var residents: [Resident] = []
    @State private var loadError: String?

    @State private var residentSelectionVisible = false
    @State private var surgerySelectionVisible = false
    @State private var complexityChosen = false
    @State private var trustChosen = false

    private var selectedResidentName: String {
        residents.first(where: { $0.id == aVM.draft.residentId })?.name ?? ""
    }

    let preselectedResidentId: String?

    init(preselectedResidentId: String? = nil) {
        self.preselectedResidentId = preselectedResidentId
    }

    private var stepCount: Int { 5 }

    private var canGoNext: Bool {
        switch step {
        case 0: return !aVM.draft.residentId.isEmpty && residentSelectionVisible
        case 1: return !aVM.draft.surgeryType.isEmpty && surgerySelectionVisible
        case 2: return complexityChosen
        case 3: return trustChosen
        default: return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    progressHeader
                    pages
                    bottomBar
                }
            }
            .navigationTitle("New Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    residents = try await api.residents()
                    if let id = preselectedResidentId, !id.isEmpty {
                        aVM.draft.residentId = id
                        residentSelectionVisible = residents.contains(where: { $0.id == id && $0.active })
                        step = 1
                    }
                } catch {
                    loadError = "Failed to load residents"
                }
            }
        }
        .interactiveDismissDisabled(true)
    }
}

private extension NewAssessmentWizard {
    func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }

    var progressHeader: some View {
        ProgressView(value: Double(step), total: Double(stepCount))
            .tint(Theme.accent)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 16)
            .padding(.top, 12)
    }

    @ViewBuilder
    var pages: some View {
        TabView(selection: $step) {
            SelectResidentStep(
                selectedId: $aVM.draft.residentId,
                residents: residents,
                isSelectionVisible: $residentSelectionVisible
            )
            .erased()
            .tag(0)

            SurgeryTypeStep(
                surgeryType: $aVM.draft.surgeryType,
                isSelectionVisible: $surgerySelectionVisible
            )
            .erased()
            .tag(1)

            ComplexityStep(
                selection: $aVM.draft.complexity,
                didChoose: $complexityChosen
            )
            .erased()
            .tag(2)

            TrustStep(
                selection: $aVM.draft.trustLevel,
                didChoose: $trustChosen
            )
            .erased()
            .tag(3)

            FeedbackStep(text: $aVM.draft.feedback)
                .erased()
                .tag(4)

            ReviewStep(
                submit: submit,
                draft: aVM.draft,
                residentName: selectedResidentName
            )
            .erased()
            .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .gesture(DragGesture().onChanged { _ in }.onEnded { _ in })
    }

    var bottomBar: some View {
        VStack(spacing: 12) {
            Divider().padding(.horizontal, 8)
            HStack(spacing: 12) {
                Button {
                    dismissKeyboard()
                    withAnimation(.easeInOut) {
                        if step == 0 { dismiss() } else { step -= 1 }
                    }
                } label: {
                    Text(step == 0 ? "Close" : "Back")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)

                Button {
                    dismissKeyboard()
                    withAnimation(.easeInOut) {
                        if step < stepCount { step += 1 } else { submit() }
                    }
                } label: {
                    Text(step == stepCount ? "Submit" : "Next")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(!canGoNext)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg)
    }

    func submit() {
        dismissKeyboard()
        Task {
            aVM.isSubmitting = true
            do {
                try await api.createAssessment(aVM.draft)
                aVM.submitted = true
                aVM.reset()
                dismiss()
            } catch {
                aVM.error = "Submit failed"
            }
            aVM.isSubmitting = false
        }
    }
}

struct SelectResidentStep: View {
    @Binding var selectedId: String
    let residents: [Resident]
    @Binding var isSelectionVisible: Bool
    @State private var search = ""

    private var filtered: [Resident] {
        let base: [Resident] = residents.filter { $0.active }
        if search.isEmpty { return base.sorted { $0.name < $1.name } }
        return base
            .filter { $0.name.localizedCaseInsensitiveContains(search) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 12) {
            searchField
            results
        }
        .onAppear { updateSelectionVisibility() }
        .onChange(of: search) { updateSelectionVisibility() }
        .onChange(of: selectedId) { updateSelectionVisibility() }
        .background(Theme.bg)
    }

    private var searchField: some View {
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
        .padding(.top, 8)
    }

    @ViewBuilder
    private var results: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filtered.isEmpty && !residents.isEmpty {
                    emptyState
                        .padding(.top, 24)
                } else {
                    ForEach(filtered) { r in
                        ResidentRowCard(
                            resident: r,
                            selected: r.id == selectedId,
                            onTap: {
                                selectedId = r.id
                                #if canImport(UIKit)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                #endif
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.subtext)
            Text("No matches")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Text("Try a different name")
                .font(.subheadline)
                .foregroundStyle(Theme.subtext)
        }
    }

    private func updateSelectionVisibility() {
        isSelectionVisible = !selectedId.isEmpty && filtered.contains(where: { $0.id == selectedId })
    }
}

enum BreastSurgeries {
    static let common: [String] = [
        "Lumpectomy (Partial Mastectomy)",
        "Re-excision of Margins",
        "Wire/Seed-Localized Excision",
        "Excisional Biopsy",
        "Incisional Biopsy",
        "Simple Mastectomy",
        "Skin-Sparing Mastectomy",
        "Nipple-Sparing Mastectomy",
        "Modified Radical Mastectomy",
        "Radical Mastectomy",
        "Sentinel Lymph Node Biopsy",
        "Axillary Lymph Node Dissection",
        "Oncoplastic Reduction",
        "Mastectomy with Immediate Reconstruction",
        "Duct Excision (Hadfield)",
        "Nipple Duct Exploration",
        "Breast Abscess Incision & Drainage",
        "Excision of Fibroadenoma",
        "Excision of Phyllodes Tumor",
        "Excision of Accessory Breast Tissue",
        "Gynecomastia Excision"
    ]
}

struct SurgeryTypeStep: View {
    @Binding var surgeryType: String
    @Binding var isSelectionVisible: Bool
    @State private var search = ""

    private var filtered: [String] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return BreastSurgeries.common }
        return BreastSurgeries.common.filter { $0.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        VStack(spacing: 12) {
            searchField
            results
        }
        .onAppear { updateSelectionVisibility() }
        .onChange(of: search) { updateSelectionVisibility() }
        .onChange(of: surgeryType) { updateSelectionVisibility() }
        .background(Theme.bg)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.subtext)
            TextField("Search surgeries", text: $search)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var results: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Theme.subtext)
                        Text("No matches")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Text("Try a different term")
                            .font(.subheadline)
                            .foregroundStyle(Theme.subtext)
                    }
                    .padding(.top, 24)
                } else {
                    ForEach(filtered, id: \.self) { item in
                        SurgeryRowCard(
                            title: item,
                            selected: item == surgeryType,
                            onTap: {
                                surgeryType = item
                                #if canImport(UIKit)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                #endif
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func updateSelectionVisibility() {
        isSelectionVisible = !surgeryType.isEmpty && filtered.contains(surgeryType)
    }
}

struct ComplexityStep: View {
    @Binding var selection: CaseComplexity?
    @Binding var didChoose: Bool

    private struct Item: Identifiable {
        let id = UUID()
        let value: CaseComplexity
        let title: String
        let subtitle: String
        let symbol: String
    }

    private let items: [Item] = [
        Item(value: .Low,      title: "Low",      subtitle: "Straightforward case; minimal decision-making and limited steps.", symbol: "1.circle.fill"),
        Item(value: .Moderate, title: "Moderate", subtitle: "Typical case with standard variations and intra-op judgment.",      symbol: "2.circle.fill"),
        Item(value: .High,     title: "High",     subtitle: "Complex anatomy, difficult exposure, or major intra-op decisions.", symbol: "3.circle.fill")
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Case Complexity")
                .font(.headline)
                .foregroundStyle(Theme.text)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        ComplexityCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            symbol: item.symbol,
                            selected: selection == item.value
                        )
                        .onTapGesture {
                            selection = item.value
                            didChoose = true
                            #if canImport(UIKit)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            #endif
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Theme.bg)
    }
}

struct TrustStep: View {
    @Binding var selection: TrustLevel?
    @Binding var didChoose: Bool

    private struct Item: Identifiable {
        let id = UUID()
        let value: TrustLevel
        let title: String
        let subtitle: String
        let symbol: String
    }

    private let items: [Item] = [
        Item(value: .DirectSupervision,  title: "Direct Supervision",  subtitle: "Attending directly observes and guides the resident.",                          symbol: "eye.trianglebadge.exclamationmark"),
        Item(value: .IndirectSupervision,title: "Indirect Supervision",subtitle: "Resident performs independently; attending immediately available.",              symbol: "person.fill.checkmark"),
        Item(value: .PracticeReady,      title: "Practice Ready",      subtitle: "Resident functions independently with full trust and minimal oversight.",       symbol: "star.fill")
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Trust Level")
                .font(.headline)
                .foregroundStyle(Theme.text)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        TrustCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            symbol: item.symbol,
                            selected: selection == item.value
                        )
                        .onTapGesture {
                            selection = item.value
                            didChoose = true
                            #if canImport(UIKit)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            #endif
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Theme.bg)
    }
}

struct FeedbackStep: View {
    @Binding var text: String
    @State private var draft = ""
    private let maxChars = 1200
    private let prompts = [
        "What went well",
        "Opportunities to improve",
        "Next steps for growth",
        "Intra-op decision making",
        "Tissue handling & hemostasis",
        "Communication & teamwork"
    ]

    private var count: Int { draft.count }
    private var progress: Double { min(Double(count) / Double(maxChars), 1.0) }

    var body: some View {
        VStack(spacing: 12) {
            Text("Feedback")
                .font(.headline)
                .foregroundStyle(Theme.text)
                .padding(.top, 8)
            Text("Summarize strengths, areas for improvement, and actionable next steps.")
                .font(.subheadline)
                .foregroundStyle(Theme.subtext)
                .padding(.horizontal, 16)
                .multilineTextAlignment(.center)

            ChipsGrid(items: prompts) { chip in
                if draft.isEmpty { draft = chip + ": " }
                else { draft += (draft.hasSuffix(" ") ? "" : " ") + chip + ": " }
            }
            .padding(.horizontal, 16)

            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("Type detailed, actionable feedback…")
                        .foregroundStyle(Theme.subtext)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                }
                TextEditor(text: $draft)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 16)

            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .tint(Theme.accent)
                    .frame(height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                HStack {
                    Text("\(count)/\(maxChars)")
                        .font(.footnote)
                        .foregroundStyle(count > maxChars ? .red : Theme.subtext)
                    Spacer()
                    if count > maxChars {
                        Text("Too long")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear { draft = text }
        .onChange(of: draft) { oldValue, newValue in
            text = String(newValue.prefix(maxChars))
        }
        .background(Theme.bg)
    }
}

private struct ChipsGrid: View {
    let items: [String]
    let onTap: (String) -> Void

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 8)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { text in
                Button {
                    onTap(text)
                } label: {
                    Text(text)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.card)
                        .foregroundStyle(Theme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ReviewStep: View {
    let submit: () -> Void
    let draft: AssessmentDraft
    let residentName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.text)

                    VStack(spacing: 0) {
                        InfoRow(
                            icon: "person.fill",
                            title: "Resident",
                            value: residentName.isEmpty ? "Not selected" : residentName
                        )
                        Divider()
                        InfoRow(
                            icon: "stethoscope",
                            title: "Surgery",
                            value: draft.surgeryType.isEmpty ? "Not set" : draft.surgeryType
                        )
                    }
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Assessment")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    HStack(spacing: 8) {
                        Pill(
                            text: draft.complexity?.rawValue ?? "Not selected",
                            systemImage: "chart.bar.fill",
                            highlighted: draft.complexity != nil
                        )
                        Pill(
                            text: draft.trustLevel?.rawValue ?? "Not selected",
                            systemImage: "lock.open.trianglebadge.exclamationmark",
                            highlighted: draft.trustLevel != nil
                        )
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback")
                        .font(.headline)
                        .foregroundStyle(Theme.text)

                    if draft.feedback.isEmpty {
                        Text("No feedback provided")
                            .foregroundStyle(Theme.subtext)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        Text(draft.feedback)
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Theme.bg)
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Theme.subtext)
                Text(value)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding(14)
    }
}

struct Pill: View {
    let text: String
    let systemImage: String
    let highlighted: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(text)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(highlighted ? Theme.accent.opacity(0.15) : Theme.card)
        .foregroundStyle(highlighted ? Theme.accent : Theme.text)
        .clipShape(Capsule())
    }
}

private struct ResidentRowCard: View {
    let resident: Resident
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(resident.name)
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Text("PGY \(resident.pgYear)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtext)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Theme.accent : .clear, lineWidth: 1.4)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

private struct SurgeryRowCard: View {
    let title: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "scalpel.line.dashed")
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.leading)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Theme.accent : .clear, lineWidth: 1.4)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

private struct ComplexityCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Theme.accent)
                    }
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Theme.accent : .clear, lineWidth: 1.4)
        )
        .contentShape(Rectangle())
    }
}

private struct TrustCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let selected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Theme.accent)
                    }
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(selected ? Theme.accent : .clear, lineWidth: 1.4)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    NewAssessmentWizard()
        .environmentObject(APIClient(auth: AuthStore()))
        .environmentObject(AssessmentViewModel())
}
