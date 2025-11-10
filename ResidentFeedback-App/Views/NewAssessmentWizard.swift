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
    @State private var residentSelectionVisible = false
    @State private var surgerySelectionVisible = false
    @State private var complexityChosen = false
    @State private var trustChosen = false
    let preselectedResidentId: String?

    init(preselectedResidentId: String? = nil) {
        self.preselectedResidentId = preselectedResidentId
    }

    private var stepCount: Int { 5 }
    private var canGoNext: Bool {
        switch step {
        case 0:
            return !aVM.draft.residentId.isEmpty && residentSelectionVisible
        case 1:
            return !aVM.draft.surgeryType.isEmpty && surgerySelectionVisible
        case 2:
            return complexityChosen
        case 3:
            return trustChosen
        default:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ProgressView(value: Double(step), total: Double(stepCount))
                        .tint(.accentColor)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    TabView(selection: $step) {
                        SelectResidentStep(
                            selectedId: $aVM.draft.residentId,
                            residents: residents,
                            isSelectionVisible: $residentSelectionVisible
                        )
                        .tag(0)

                        SurgeryTypeStep(
                            surgeryType: $aVM.draft.surgeryType,
                            isSelectionVisible: $surgerySelectionVisible
                        )
                        .tag(1)

                        ComplexityStep(selection: $aVM.draft.complexity, didChoose: $complexityChosen)
                            .tag(2)

                        TrustStep(selection: $aVM.draft.trustLevel, didChoose: $trustChosen)
                            .tag(3)

                        FeedbackStep(text: $aVM.draft.feedback)
                            .tag(4)

                        ReviewStep(submit: submit, draft: aVM.draft)
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))

                    VStack(spacing: 12) {
                        Divider().padding(.horizontal, 8)
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.easeInOut) {
                                    if step == 0 { dismiss() } else { step -= 1 }
                                }
                            } label: {
                                Text(step == 0 ? "Close" : "Back")
                                    .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                withAnimation(.easeInOut) {
                                    if step < stepCount { step += 1 } else { submit() }
                                }
                            } label: {
                                Text(step == stepCount ? "Submit" : "Next")
                                    .frame(maxWidth: .infinity, minHeight: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canGoNext)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .background(Color(.systemBackground))
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

    private func submit() {
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
        residents
            .filter { $0.active }
            .filter { r in
                search.isEmpty || r.name.localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search residents", text: $search)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if filtered.isEmpty && !residents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("No matches").font(.headline)
                            Text("Try a different name").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                    } else {
                        ForEach(filtered) { r in
                            ResidentRowCard(
                                resident: r,
                                selected: r.id == selectedId,
                                onTap: { selectedId = r.id }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear { updateSelectionVisibility() }
        .onChange(of: search) { updateSelectionVisibility() }
        .onChange(of: selectedId) { updateSelectionVisibility() }
        .background(Color(.systemBackground))
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
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search surgeries", text: $search)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if filtered.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "questionmark.folder")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("No matches").font(.headline)
                            Text("Try a different term").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                    } else {
                        ForEach(filtered, id: \.self) { item in
                            SurgeryRowCard(
                                title: item,
                                selected: item == surgeryType,
                                onTap: { surgeryType = item }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear { updateSelectionVisibility() }
        .onChange(of: search) { updateSelectionVisibility() }
        .onChange(of: surgeryType) { updateSelectionVisibility() }
        .background(Color(.systemBackground))
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
        Item(value: .Low, title: "Low", subtitle: "Straightforward case; minimal decision-making and limited steps.", symbol: "1.circle.fill"),
        Item(value: .Moderate, title: "Moderate", subtitle: "Typical case with standard variations and intra-op judgment.", symbol: "2.circle.fill"),
        Item(value: .High, title: "High", subtitle: "Complex anatomy, difficult exposure, or major intra-op decisions.", symbol: "3.circle.fill")
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Case Complexity").font(.headline).padding(.top, 8)
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
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
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
        Item(value: .DirectSupervision, title: "Direct Supervision", subtitle: "Attending directly observes and guides the resident.", symbol: "eye.trianglebadge.exclamationmark"),
        Item(value: .IndirectSupervision, title: "Indirect Supervision", subtitle: "Resident performs independently; attending immediately available.", symbol: "person.fill.checkmark")
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Trust Level").font(.headline).padding(.top, 8)
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
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
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

    var count: Int { draft.count }
    var progress: Double { min(Double(count) / Double(maxChars), 1.0) }

    var body: some View {
        VStack(spacing: 12) {
            Text("Feedback").font(.headline).padding(.top, 8)
            Text("Summarize strengths, areas for improvement, and actionable next steps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .multilineTextAlignment(.center)

            WrapChips(items: prompts) { chip in
                if draft.isEmpty { draft = chip + ": " }
                else { draft += (draft.hasSuffix(" ") ? "" : " ") + chip + ": " }
            }
            .padding(.horizontal, 16)

            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("Type detailed, actionable feedback…")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 12)
                }
                TextEditor(text: $draft)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 16)

            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .tint(.accentColor)
                    .frame(height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                HStack {
                    Text("\(count)/\(maxChars)")
                        .font(.footnote)
                        .foregroundStyle(count > maxChars ? .red : .secondary)
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
        .background(Color(.systemBackground))
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
                HStack { Text("Complexity"); Spacer(); Text(draft.complexity?.rawValue ?? "Not selected") }
                HStack { Text("Trust"); Spacer(); Text(draft.trustLevel?.rawValue ?? "Not selected") }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Feedback").bold()
                Text(draft.feedback.isEmpty ? "None" : draft.feedback)
            }
            Button(action: submit) { Text("Submit Assessment").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

private struct ResidentRowCard: View {
    let resident: Resident
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.fill").foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(resident.name).font(.headline)
                Text("PGY \(resident.pgYear)").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.4))
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
            Image(systemName: "scalpel.line.dashed").foregroundStyle(Color.accentColor)
            Text(title).font(.headline).multilineTextAlignment(.leading)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.4))
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
            Image(systemName: symbol).font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.accentColor).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.hierarchical).foregroundStyle(Color.accentColor)
                    }
                }
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.4))
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
            Image(systemName: symbol).font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.accentColor).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill").symbolRenderingMode(.hierarchical).foregroundStyle(Color.accentColor)
                    }
                }
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? Color.accentColor : Color.clear, lineWidth: 1.4))
        .contentShape(Rectangle())
    }
}

private struct WrapChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(items: items) { text in
            Button {
                onTap(text)
            } label: {
                Text(text)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            self.generateContent(in: proxy.size.width)
        }
        .frame(minHeight: 0)
    }

    private func generateContent(in totalWidth: CGFloat) -> some View {
        var width = CGFloat.zero
        var rows: [[Data.Element]] = [[]]
        for item in items {
            let itemWidth = estimateWidth(for: item)
            if width + itemWidth > totalWidth {
                rows.append([item])
                width = itemWidth
            } else {
                rows[rows.count - 1].append(item)
                width += itemWidth
            }
        }
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(rows[row], id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }

    private func estimateWidth(for item: Data.Element) -> CGFloat {
        let s = String(describing: item)
        let w = s.size(withAttributes: [.font: UIFont.systemFont(ofSize: 13, weight: .semibold)]).width
        return w + 20 + 12
    }
}

#Preview {
    NewAssessmentWizard()
        .environmentObject(APIClient(auth: AuthStore()))
        .environmentObject(AssessmentViewModel())
}
