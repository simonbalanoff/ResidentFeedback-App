//
//  Config.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation

enum AppEnv {
    static let isProduction = true
    static var baseURL: URL {
        isProduction ?
        URL(string: "https://residentfeedback-api.onrender.com/")! :
        URL(string: "http://localhost:3000/")!
    }
}
