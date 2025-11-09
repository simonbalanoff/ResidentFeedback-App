//
//  RootTabView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

private enum Tab { case residents, settings }

struct RootTabView: View {
    @State private var selected: Tab = .residents
    @State private var showNew = false

    var body: some View {
        ZStack {
            Theme.gradient.ignoresSafeArea()

            Group {
                switch selected {
                case .residents: ResidentsListView()
                case .settings: SettingsView()
                }
            }
            .padding(.bottom, 72)

            VStack {
                Spacer()
                CompactTabBar(selected: $selected, plusAction: { showNew = true })
            }
        }
        .sheet(isPresented: $showNew) { NewAssessmentWizard() }
    }
}

private struct CompactTabBar: View {
    @Binding var selected: Tab
    let plusAction: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 35) {
                TabIconButton(icon: "person.3.fill", active: selected == .residents) { selected = .residents }

                Button(action: plusAction) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                            .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                TabIconButton(icon: "gearshape.fill", active: selected == .settings) { selected = .settings }
            }
            .padding(.horizontal, 28)
            .frame(height: 70)
        }
        .padding(.bottom, 10)
    }
}

private struct TabIconButton: View {
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(active ? .white : Theme.textSecondary)
                    .frame(height: 36)
                Circle()
                    .fill(active ? Theme.accent : .clear)
                    .frame(width: 6, height: 6)
                    .shadow(color: active ? Theme.accent.opacity(0.6) : .clear, radius: 4)
            }
        }
    }
}
