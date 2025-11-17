//
//  Theme.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

import SwiftUI

enum Theme {
    static let brandPrimary = Color(hex: "003865")
    static let brandAccent = Color(hex: "BD5B04")

    static var bg: Color { Color(.systemBackground) }
    static var card: Color { Color(.secondarySystemBackground) }
    static var sep: Color { Color(.separator) }
    static var text: Color { Color(.label) }
    static var subtext: Color { Color(.secondaryLabel) }

    static var primary: Color { brandPrimary }
    static var accent: Color { brandAccent }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
