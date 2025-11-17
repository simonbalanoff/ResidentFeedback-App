//
//  UIComponents.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.sep))
    }
}

struct IconField: View {
    let systemImage: String
    let title: String
    @Binding var text: String
    var isSecure = false
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage).foregroundStyle(Theme.subtext)
                .frame(width: 24)
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Theme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.sep))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.white)
            Text(message).foregroundStyle(.white).font(.subheadline)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview("Card") {
    Card { Text("Card") }.padding()
}

#Preview("IconField") {
    IconField(systemImage: "envelope.fill", title: "Email", text: .constant("me@example.com"))
        .padding()
}

#Preview("PrimaryButtonStyle") {
    Button("Continue") {}
        .buttonStyle(PrimaryButtonStyle())
        .padding()
}

#Preview("ErrorBanner") {
    ErrorBanner(message: "Something went wrong")
        .padding()
}
