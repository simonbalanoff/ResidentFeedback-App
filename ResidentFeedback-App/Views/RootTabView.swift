//
//  RootTabView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

private enum Tab: Hashable { case residents, settings }

struct RootTabView: View {
    @State private var selected: Tab = .residents
    @State private var showNew = false
    @Namespace private var ns

    var body: some View {
        ZStack {
            Theme.bg
                .ignoresSafeArea()

            NavigationStack {
                ResidentsListView(startNewAssessment: { showNew = true })
            }
            .tint(Theme.accent)
            .opacity(selected == .residents ? 1 : 0)
            .allowsHitTesting(selected == .residents)

            NavigationStack {
                SettingsView()
            }
            .tint(Theme.accent)
            .opacity(selected == .settings ? 1 : 0)
            .allowsHitTesting(selected == .settings)

            VStack { Spacer() }
                .safeAreaInset(edge: .bottom) {
                    FloatingTabBar(
                        selected: $selected,
                        plusTapped: { showNew = true },
                        ns: ns
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                }
        }
        .fullScreenCover(isPresented: $showNew) {
            NewAssessmentWizard()
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selected: Tab
    let plusTapped: () -> Void
    let ns: Namespace.ID
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 14) {
            TabButton(
                icon: "person.3.fill",
                title: "Residents",
                active: selected == .residents,
                ns: ns
            ) { tap(.residents) }

            Button(action: plusTapped) {
                ZStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 58, height: 58)
                        .shadow(
                            color: Theme.accent.opacity(scheme == .dark ? 0.35 : 0.25),
                            radius: 12,
                            y: 6
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel("New Assessment")

            TabButton(
                icon: "gearshape.fill",
                title: "Settings",
                active: selected == .settings,
                ns: ns
            ) { tap(.settings) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.card, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Theme.sep.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }

    func tap(_ tab: Tab) {
        selected = tab
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct TabButton: View {
    let icon: String
    let title: String
    let active: Bool
    let ns: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottom) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(active ? Theme.primary : Theme.subtext)

                    Color.clear
                        .frame(width: 16, height: 3)
                        .offset(y: 8)
                }
                Text(title)
                    .font(.footnote.weight(active ? .semibold : .regular))
                    .foregroundStyle(active ? Theme.primary : Theme.subtext)
            }
            .frame(width: 110, height: 48, alignment: .center)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(APIClient(auth: AuthStore()))
        .environmentObject(AuthStore())
        .environmentObject(AssessmentViewModel())
        .environmentObject(AppearanceStore())
}
