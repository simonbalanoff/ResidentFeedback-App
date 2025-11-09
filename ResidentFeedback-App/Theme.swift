//
//  Theme.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

enum Theme {
    static let gradient = LinearGradient(colors: [
        Color(hex: 0x0F172A),
        Color(hex: 0x1E293B),
        Color(hex: 0x0B1220)
    ], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    static let cardBackground = Color.white.opacity(0.08)
    static let stroke = Color.white.opacity(0.15)
    static let fill = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let accent = Color(hex: 0x60A5FA)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
