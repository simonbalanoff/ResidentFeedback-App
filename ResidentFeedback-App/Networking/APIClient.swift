//
//  APIClient.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation
internal import Combine

@MainActor
final class APIClient: ObservableObject {
    var objectWillChange = PassthroughSubject<APIClient, Never>()
    
    let auth: AuthStore
    let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.waitsForConnectivity = true
        return URLSession(configuration: c)
    }()
    init(auth: AuthStore) { self.auth = auth }
    
    func request(_ path: String, method: String = "GET", body: Encodable? = nil, authorized: Bool = true) async throws -> (Data, HTTPURLResponse) {
        var url = AppEnv.baseURL
        url.append(path: path)
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let b = body { r.httpBody = try JSONEncoder().encode(AnyEncodable(b)) }
        if authorized, let t = auth.accessToken { r.addValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await session.data(for: r)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401, authorized {
            try await refresh()
            return try await request(path, method: method, body: body, authorized: true)
        }
        return (data, http)
    }
    
    func login(email: String, password: String) async throws {
        let (d, http) = try await request("auth/login", method: "POST", body: ["email": email, "password": password], authorized: false)
        guard http.statusCode == 200 else { throw URLError(.userAuthenticationRequired) }
        let obj = try JSONDecoder().decode(TokenPair.self, from: d)
        auth.setTokens(access: obj.accessToken, refresh: obj.refreshToken)
        try await loadMe()
    }
    
    func register(name: String, email: String, password: String) async throws {
        let (d, http) = try await request("auth/register", method: "POST", body: ["name": name, "email": email, "password": password], authorized: false)
        guard http.statusCode == 201 else { throw URLError(.badServerResponse) }
        let obj = try JSONDecoder().decode(TokenPair.self, from: d)
        auth.setTokens(access: obj.accessToken, refresh: obj.refreshToken)
        try await loadMe()
    }
    
    func refresh() async throws {
        guard let rt = auth.refreshToken else { throw URLError(.userAuthenticationRequired) }
        let (d, http) = try await request("auth/refresh", method: "POST", body: ["refreshToken": rt], authorized: false)
        guard http.statusCode == 200 else { throw URLError(.userAuthenticationRequired) }
        let o = try JSONDecoder().decode(TokenPair.self, from: d)
        auth.setTokens(access: o.accessToken, refresh: rt)
    }
    
    func loadMe() async throws {
        let (d, http) = try await request("auth/me", authorized: true)
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        auth.me = try JSONDecoder().decode(Me.self, from: d)
    }
    
    func residents() async throws -> [Resident] {
        let (d, http) = try await request("residents", authorized: true)
        guard http.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode([Resident].self, from: d)
    }
    
    func createAssessment(_ draft: AssessmentDraft) async throws {
        let (_, http) = try await request("assessments", method: "POST", body: draft, authorized: true)
        guard http.statusCode == 201 else { throw URLError(.badServerResponse) }
    }
}

struct TokenPair: Codable { let accessToken: String; let refreshToken: String }
struct AccessOnly: Codable { let accessToken: String }

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ value: Encodable) { self.encodeFunc = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
