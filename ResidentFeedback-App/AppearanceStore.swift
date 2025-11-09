//
//  AppearanceStore.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/9/25.
//

import SwiftUI
internal import Combine

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
}

@MainActor
final class AppearanceStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @AppStorage("appearanceMode") var raw: String = AppearanceMode.system.rawValue
    var mode: AppearanceMode { AppearanceMode(rawValue: raw) ?? .system }
    func set(_ m: AppearanceMode) { raw = m.rawValue; objectWillChange.send() }
    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
