//
//  ResidentsListView.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import SwiftUI

struct ResidentsListView: View {
    @EnvironmentObject var api: APIClient
    @State private var residents: [Resident] = []
    @State private var loading = true
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Group {
                if loading { ProgressView() }
                else if let e = error { Text(e).foregroundColor(.red) }
                else {
                    List(residents) { r in
                        VStack(alignment: .leading) {
                            Text(r.name).font(.headline)
                            Text("PGY \(r.pgYear)").font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Residents")
            .task {
                do { residents = try await api.residents() } catch { self.error = "Failed to load residents" }
                loading = false
            }
        }
    }
}
