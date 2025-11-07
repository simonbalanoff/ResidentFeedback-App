//
//  Keychain.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/7/25.
//

import Foundation
import Security

final class Keychain {
    static func set(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        var q = query
        q[kSecValueData as String] = data
        SecItemAdd(q as CFDictionary, nil)
    }
    
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }
    
    static func remove(_ key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
    }
}
