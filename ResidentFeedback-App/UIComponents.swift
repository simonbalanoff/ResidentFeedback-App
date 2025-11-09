//
//  UIComponents.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(22)
            .background(Theme.cardBackground)
            .background(.ultraThinMaterial.opacity(0.2))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 30)
    }
}

struct IconField: View {
    let systemImage: String
    let title: String
    @Binding var text: String
    var isSecure = false
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).foregroundStyle(Theme.textSecondary)
            if isSecure {
                SecureField("", text: $text, prompt: Text( title).foregroundColor(.white.opacity(0.5)))
                    .textContentType(.password)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                TextField("", text: $text, prompt: Text(title).foregroundColor(.white.opacity(0.5)))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Theme.fill)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .shadow(color: Theme.accent.opacity(0.4), radius: 16, x: 0, y: 10)
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
            Text(message).foregroundStyle(.white).font(.subheadline)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.red.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 14, x: 0, y: 10)
    }
}

struct AppLogo: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.accent.opacity(0.2)).frame(width: 86, height: 86)
            Image(systemName: "stethoscope")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: Theme.accent.opacity(0.45), radius: 18, x: 0, y: 10)
    }
}
