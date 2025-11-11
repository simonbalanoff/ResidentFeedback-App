//
//  BiometricAuth.swift
//  ResidentFeedback-App
//
//  Created by Simon Balanoff on 11/10/25.
//

import LocalAuthentication

enum BiometricAuth {
    static func authenticate(reason: String = "Authenticate to continue") async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return false }
        return await withCheckedContinuation { cont in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                cont.resume(returning: success)
            }
        }
    }
    
    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}
