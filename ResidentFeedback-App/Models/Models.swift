//
//  Models.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation

struct Me: Codable {
    let id: String
    let email: String
    let name: String
    let role: String
}

struct Resident: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let pgYear: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case pgYear
        case active
    }
}

enum CaseComplexity: String, CaseIterable, Identifiable, Codable {
    case Low
    case Moderate
    case High

    var id: String { rawValue }
}

enum TrustLevel: String, CaseIterable, Identifiable, Codable {
    case LimitedParticipation = "Limited Participation"
    case DirectSupervision = "Direct Supervision"
    case IndirectSupervision = "Indirect Supervision"
    case PracticeReady = "Practice Ready"

    var id: String { rawValue }
}

struct AssessmentDraft: Codable {
    var residentId: String = ""
    var surgeryType: String = ""
    var complexity: CaseComplexity?
    var trustLevel: TrustLevel?
    var feedback: String = ""
    var note: String? = nil
}

struct Assessment: Identifiable, Codable {
    let id: String
    let surgeonId: String
    let residentId: String
    let surgeryType: String
    let complexity: CaseComplexity?
    let trustLevel: TrustLevel?
    let note: String?
    let feedback: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case surgeonId
        case residentId
        case surgeryType
        case complexity
        case trustLevel
        case note
        case feedback
        case createdAt
    }
}
