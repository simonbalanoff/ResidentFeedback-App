//
//  AssessmentRow.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/17/25.
//

import SwiftUI

struct AssessmentRow: View {
    let assessment: Assessment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(assessment.surgeryType)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .layoutPriority(10)

                HStack(spacing: 6) {
                    if let complexity = assessment.complexity {
                        Text(complexityDisplay(complexity))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.card, in: Capsule())
                            .foregroundStyle(Theme.subtext)
                            .fixedSize()
                    }
                    if let trust = assessment.trustLevel {
                        Text(trustDisplay(trust))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                            .foregroundStyle(Theme.accent)
                            .fixedSize()
                    }
                }
                .lineLimit(1)
                .layoutPriority(10)

                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(Theme.subtext)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let created = assessment.createdAt {
                    Text(created, style: .date)
                        .font(.caption2)
                        .foregroundStyle(Theme.subtext)
                } else {
                    Text("No date")
                        .font(.caption2)
                        .foregroundStyle(Theme.subtext.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 4)
    }

    var snippet: String {
        if let note = assessment.note, !note.isEmpty {
            return note
        }
        return assessment.feedback
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
