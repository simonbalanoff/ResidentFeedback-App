//
//  RootTabView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var auth: AuthStore
    @State private var showNew = false
    var body: some View {
        ZStack {
            TabView {
                ResidentsListView()
                    .tabItem { Label("Residents", systemImage: "person.3") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 64))
                    }
                    .padding(.trailing, 20).padding(.bottom, 10)
                }
            }
        }
        .sheet(isPresented: $showNew) { NewAssessmentWizard() }
    }
}
