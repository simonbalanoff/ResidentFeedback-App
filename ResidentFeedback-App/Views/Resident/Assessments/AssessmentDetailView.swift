//
//  AssessmentDetailView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/17/25.
//

import SwiftUI

struct AssessmentDetailView: View {
    let assessment: Assessment
    let resident: Resident

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resident.name)
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        if let created = assessment.createdAt {
                            Text(created, style: .date)
                                .font(.caption)
                                .foregroundStyle(Theme.subtext)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(assessment.surgeryType)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.text)

                        HStack(spacing: 6) {
                            if let complexity = assessment.complexity {
                                Text(complexityDisplay(complexity))
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.card, in: Capsule())
                                    .foregroundStyle(Theme.subtext)
                            }
                            if let trust = assessment.trustLevel {
                                Text(trustDisplay(trust))
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.accent.opacity(0.16), in: Capsule())
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .lineLimit(1)
                        .layoutPriority(10)
                    }
                }

                Divider()

                if let note = assessment.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.subtext)
                        Text(note)
                            .font(.body)
                            .foregroundStyle(Theme.text)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Feedback")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.subtext)
                    Text(assessment.feedback)
                        .font(.body)
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .navigationTitle("Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
    }

    func complexityDisplay(_ c: CaseComplexity) -> String {
        switch c {
        case .Low: return "Low complexity"
        case .Moderate: return "Moderate"
        case .High: return "High"
        }
    }

    func trustDisplay(_ t: TrustLevel) -> String {
        switch t {
        case .LimitedParticipation: return "Limited Participation"
        case .DirectSupervision: return "Direct Supervision"
        case .IndirectSupervision: return "Indirect Supervision"
        case .PracticeReady: return "Practice Ready"
        }
    }
}

