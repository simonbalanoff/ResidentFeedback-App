//
//  AssessmentViewModel.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation
internal import Combine

@MainActor
final class AssessmentViewModel: ObservableObject {
    @Published var residents: [Resident] = []
    @Published var draft = AssessmentDraft()
    @Published var isSubmitting = false
    @Published var submitted = false
    @Published var error: String?
    
    func reset() {
        draft = AssessmentDraft()
        submitted = false
        error = nil
    }
}
