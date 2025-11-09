//
//  Theme.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

enum Theme {
    static var bg: Color { Color(.systemBackground) }
    static var card: Color { Color(.secondarySystemBackground) }
    static var sep: Color { Color(.separator) }
    static var text: Color { Color(.label) }
    static var subtext: Color { Color(.secondaryLabel) }
    static var accent: Color { Color.accentColor }
}

#Preview {
    VStack(spacing: 12) {
        Text("Primary").foregroundStyle(Theme.text)
        Text("Secondary").foregroundStyle(Theme.subtext)
        RoundedRectangle(cornerRadius: 12).fill(Theme.card).frame(height: 60)
    }
    .padding()
    .background(Theme.bg)
}
