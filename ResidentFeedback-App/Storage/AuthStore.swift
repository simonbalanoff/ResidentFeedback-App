//
//  AuthStore.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation
internal import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published var accessToken: String? = Keychain.get("accessToken")
    @Published var refreshToken: String? = Keychain.get("refreshToken")
    @Published var me: Me?

    var isAuthenticated: Bool {
        accessToken != nil
    }

    init() {}

    func setTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        Keychain.set(access, key: "accessToken")
        Keychain.set(refresh, key: "refreshToken")
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        me = nil
        Keychain.remove("accessToken")
        Keychain.remove("refreshToken")
    }
}
