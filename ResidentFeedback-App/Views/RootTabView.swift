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
            Group {
                switch selected {
                case .residents:
                    NavigationStack { ResidentsListView(startNewAssessment: { showNew = true }) }
                        .transition(.opacity)
                case .settings:
                    NavigationStack { SettingsView() }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selected)

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
                    .background(.clear)
                }
        }
        .sheet(isPresented: $showNew) { NewAssessmentWizard() }
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
                        .fill(Color.accentColor)
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.accentColor.opacity(scheme == .dark ? 0.35 : 0.25), radius: 12, y: 6)
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
        .background(.regularMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.primary.opacity(0.08))
        )
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
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(active ? Color.primary : .secondary)
                    if active {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 3)
                            .matchedGeometryEffect(id: "underline", in: ns)
                            .offset(y: 8)
                    } else {
                        Color.clear.frame(width: 16, height: 3).offset(y: 8)
                    }
                }
                Text(title)
                    .font(.footnote.weight(active ? .semibold : .regular))
                    .foregroundStyle(active ? Color.primary : .secondary)
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
