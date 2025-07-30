//
//  KeychainManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 27/07/25.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keychain Operations
    
    func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func delete(key: String) -> OSStatus {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        return SecItemDelete(query as CFDictionary)
    }
    
    func update(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        let attributes = [
            kSecValueData as String: data
        ] as [String: Any]
        
        return SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }
    
    // MARK: - Convenience Methods for Strings
    
    func saveString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        let status = save(key: key, data: data)
        return status == errSecSuccess
    }
    
    func loadString(forKey key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteString(forKey key: String) -> Bool {
        let status = delete(key: key)
        return status == errSecSuccess
    }
    
    func updateString(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        let status = update(key: key, data: data)
        return status == errSecSuccess
    }
    
    // MARK: - Specific Keys
    
    enum KeychainKeys {
        static let jwtToken = "com.fitglide.jwt.token"
        static let userId = "com.fitglide.user.id"
        static let userEmail = "com.fitglide.user.email"
        static let userFirstName = "com.fitglide.user.firstName"
        static let stravaToken = "com.fitglide.strava.token"
        static let stravaRefreshToken = "com.fitglide.strava.refreshToken"
        static let stravaExpiresAt = "com.fitglide.strava.expiresAt"
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        let keys = [
            KeychainKeys.jwtToken,
            KeychainKeys.userId,
            KeychainKeys.userEmail,
            KeychainKeys.userFirstName,
            KeychainKeys.stravaToken,
            KeychainKeys.stravaRefreshToken,
            KeychainKeys.stravaExpiresAt
        ]
        
        for key in keys {
            _ = delete(key: key)
        }
    }
    
    // MARK: - Error Handling
    
    func getErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecParam:
            return "Invalid parameter"
        case errSecAllocate:
            return "Memory allocation failed"
        case errSecNotAvailable:
            return "No trust results available"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecDecode:
            return "Unable to decode the provided data"
        case errSecUnimplemented:
            return "Function or operation not implemented"
        default:
            return "Unknown error: \(status)"
        }
    }
} 