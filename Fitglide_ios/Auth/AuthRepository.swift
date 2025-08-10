//
//  AppleAuthManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import Foundation
import Combine
import AuthenticationServices
import UIKit

class AuthRepository: ObservableObject, TokenManager {
    struct AuthState {
        let jwt: String?
        let userId: String?
        let firstName: String? // ✅ Fetched from Strapi

        var isLoggedIn: Bool { jwt != nil }
    }

    @Published var authState: AuthState
    private let appleAuthManager: AppleAuthManager
    private let userDefaults: UserDefaults
    private let keychainManager = KeychainManager.shared
    private let baseURL = "https://admin.fitglide.in/api/"

    init(appleAuthManager: AppleAuthManager = AppleAuthManager(), userDefaults: UserDefaults = UserDefaults.standard) {
        self.appleAuthManager = appleAuthManager
        self.userDefaults = userDefaults
        
        // Try to load from Keychain first, fallback to UserDefaults
        let jwt = keychainManager.loadString(forKey: KeychainManager.KeychainKeys.jwtToken) ?? userDefaults.string(forKey: "jwt")
        let userId = keychainManager.loadString(forKey: KeychainManager.KeychainKeys.userId) ?? userDefaults.string(forKey: "userId")
        let firstName = keychainManager.loadString(forKey: KeychainManager.KeychainKeys.userFirstName) ?? userDefaults.string(forKey: "firstName")
        self.authState = AuthState(jwt: jwt, userId: userId, firstName: firstName)
    }
    
    func initializeAuth() {
        if authState.jwt != nil {
            Task { @MainActor in await self.refreshLogin() }
        }
    }
    
    func loginWithApple(completion: @escaping (Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No valid rootViewController found")
            completion(false)
            return
        }
        
        appleAuthManager.startSignIn(from: rootVC) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let signInResult):
                Task { @MainActor in
                    let success = await self.authenticateWithStrapi(
                        identityToken: signInResult.identityToken,
                        userId: signInResult.userId,
                        email: signInResult.email,
                        firstName: signInResult.firstName,
                        lastName: signInResult.lastName
                    )
                    completion(success)
                }
            case .failure(let error):
                print("Apple Sign-In failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    private func authenticateWithStrapi(
        identityToken: String,
        userId: String,
        email: String?,
        firstName: String?,
        lastName: String?
    ) async -> Bool {
        guard let url = URL(string: "\(baseURL)apple-login") else {
            print("Invalid Strapi URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["id_token": identityToken]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to encode request body: \(error)")
            return false
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Strapi login failed: \(response)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                return false
            }

            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            let jwt = loginResponse.jwt
            print("🔑 Strapi JWT Token:\n\(jwt)")
            let strapiUserId = String(loginResponse.user.id)

            // Update Strapi profile with Apple data
            let updateSuccess = await updateStrapiProfile(
                userId: strapiUserId,
                jwt: jwt,
                firstName: firstName,
                lastName: lastName,
                email: email
            )
            print("Profile update status: \(updateSuccess)")

            // Fetch updated user profile from Strapi to get firstName
            let strapiFirstName = await fetchUserProfile(userId: strapiUserId, jwt: jwt)?.firstName ?? "User"

            await MainActor.run {
                let oldAuthState = self.authState
                self.authState = AuthState(jwt: jwt, userId: strapiUserId, firstName: strapiFirstName)
                self.saveAuthStateToUserDefaults(jwt: jwt, userId: strapiUserId, firstName: strapiFirstName)
                
                // Trigger state change notification
                self.objectWillChange.send()
                
                print("✅ Authentication successful")
                print("📊 Auth state updated: \(oldAuthState.isLoggedIn) -> \(self.authState.isLoggedIn)")
                print("📊 User ID: \(strapiUserId), First Name: \(strapiFirstName)")
            }

            return true
        } catch {
            print("Strapi login error: \(error)")
            return false
        }
    }

    private func fetchUserProfile(userId: String, jwt: String) async -> UserProfile? {
        guard let url = URL(string: "\(baseURL)users/\(userId)") else {
            print("Invalid Strapi profile URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("User profile fetch failed: \(response)")
                return nil
            }

            let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
            return userProfile
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }

    private func updateStrapiProfile(
        userId: String,
        jwt: String,
        firstName: String?,
        lastName: String?,
        email: String?
    ) async -> Bool {
        guard let url = URL(string: "\(baseURL)users/\(userId)") else {
            print("Invalid Strapi profile URL")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let firstName { body["firstName"] = firstName }
        if let lastName { body["lastName"] = lastName }
        if let email, !email.isEmpty { body["email"] = email }
        
        guard !body.isEmpty else {
            print("No profile data to update")
            return true
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to encode profile update body: \(error)")
            return false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Profile update failed: \(response)")
                print("Profile update response data: \(String(data: data, encoding: .utf8) ?? "No data")")
                return false
            }
            print("Profile updated: \(String(data: data, encoding: .utf8) ?? "")")
            return true
        } catch {
            print("Profile update error: \(error)")
            return false
        }
    }
    
    private func saveAuthStateToUserDefaults(jwt: String?, userId: String?, firstName: String?) {
        // Save to Keychain for secure storage
        if let jwt = jwt {
            _ = keychainManager.saveString(jwt, forKey: KeychainManager.KeychainKeys.jwtToken)
        } else {
            _ = keychainManager.deleteString(forKey: KeychainManager.KeychainKeys.jwtToken)
        }
        
        if let userId = userId {
            _ = keychainManager.saveString(userId, forKey: KeychainManager.KeychainKeys.userId)
        } else {
            _ = keychainManager.deleteString(forKey: KeychainManager.KeychainKeys.userId)
        }
        
        if let firstName = firstName {
            _ = keychainManager.saveString(firstName, forKey: KeychainManager.KeychainKeys.userFirstName)
        } else {
            _ = keychainManager.deleteString(forKey: KeychainManager.KeychainKeys.userFirstName)
        }
        
        // Also save to UserDefaults as backup
        userDefaults.set(jwt, forKey: "jwt")
        userDefaults.set(userId, forKey: "userId")
        userDefaults.set(firstName, forKey: "firstName")
        userDefaults.synchronize()
    }
    
    func isLoggedIn() -> Bool {
        authState.isLoggedIn
    }
    
    func logout() {
        Task { @MainActor in
            print("🔄 Starting logout process...")
            
            // Step 1: Clear local auth state
            let oldAuthState = self.authState
            self.authState = AuthState(jwt: nil, userId: nil, firstName: nil)
            
            // Step 2: Clear authentication data from storage
            self.saveAuthStateToUserDefaults(jwt: nil, userId: nil, firstName: nil)
            
            // Step 3: Clear essential login data from UserDefaults
            UserDefaults.standard.removeObject(forKey: "jwt")
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "firstName")
            UserDefaults.standard.synchronize()
            
            // Step 4: Trigger state change notification
            objectWillChange.send()
            
            print("✅ User successfully signed out")
            print("📊 Auth state changed: \(oldAuthState.isLoggedIn) -> \(self.authState.isLoggedIn)")
        }
    }
    
    private func signOutFromApple() async {
        // Apple doesn't provide a direct sign-out method, but we can clear the state
        // The user will need to sign in again with Apple if they want to use the app
        print("🔄 Clearing Apple Sign-In state")
    }
    
    private func clearCachedData() async {
        // Clear ALL user data from UserDefaults to ensure a clean slate
        let userDefaults = UserDefaults.standard
        
        // Authentication data
        userDefaults.removeObject(forKey: "jwt")
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "firstName")
        
        // Health and fitness data
        userDefaults.removeObject(forKey: "steps")
        userDefaults.removeObject(forKey: "hydration")
        userDefaults.removeObject(forKey: "heartRate")
        userDefaults.removeObject(forKey: "caloriesBurned")
        userDefaults.removeObject(forKey: "sleepHours")
        userDefaults.removeObject(forKey: "bmr")
        userDefaults.removeObject(forKey: "hydrationGoal")
        userDefaults.removeObject(forKey: "wakeUpTime")
        userDefaults.removeObject(forKey: "bedTime")
        userDefaults.removeObject(forKey: "trackedSteps")
        userDefaults.removeObject(forKey: "isTracking")
        userDefaults.removeObject(forKey: "isPaused")
        
        // App preferences
        userDefaults.removeObject(forKey: "hydrationRemindersEnabled")
        userDefaults.removeObject(forKey: "show_stories")
        userDefaults.removeObject(forKey: "sleepSyncEnabled")
        userDefaults.removeObject(forKey: "sleepGoal")
        userDefaults.removeObject(forKey: "sleepSound")
        userDefaults.removeObject(forKey: "userBedtime")
        userDefaults.removeObject(forKey: "userWakeTime")
        userDefaults.removeObject(forKey: "meditationSessions")
        userDefaults.removeObject(forKey: "sleepTimerSessions")
        
        // Messages and notifications
        userDefaults.removeObject(forKey: "maxMessageYesterday")
        userDefaults.removeObject(forKey: "maxMessageToday")
        userDefaults.removeObject(forKey: "maxMessageHasPlayed")
        userDefaults.removeObject(forKey: "lastActivityTime")
        
        // Achievement and gamification data
        userDefaults.removeObject(forKey: "unlockedAchievements")
        userDefaults.removeObject(forKey: "levelProgress")
        userDefaults.removeObject(forKey: "fitCoinsWallet")
        
        // Cached data
        userDefaults.removeObject(forKey: "cachedHealthData")
        userDefaults.removeObject(forKey: "cachedProfileData")
        userDefaults.removeObject(forKey: "cachedGoals")
        
        // Synchronize to ensure all changes are saved
        userDefaults.synchronize()
        
        print("🗑️ Cleared all user data from UserDefaults")
    }
    
    private func resetAchievementSystem() async {
        // Reset the achievement system to clear all user progress
        await MainActor.run {
            AchievementManager.shared.resetAll()
        }
        print("🏆 Reset achievement system")
    }
    
    private func clearNotifications() async {
        // Clear all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔔 Cleared all pending notifications")
    }
    
    // MARK: - Account Deletion
    
    /// Comprehensive account deletion that removes all user data before deleting the account
    func deleteAccount() async -> (success: Bool, message: String) {
        guard let userId = authState.userId, let jwt = authState.jwt else {
            return (false, "No user logged in")
        }
        
        do {
            // Step 1: Delete all user data from Strapi collections
            let deletionResults = await deleteAllUserData(userId: userId, jwt: jwt)
            
            // Step 2: Delete the user account from Strapi
            let userDeletionSuccess = await deleteUserAccount(userId: userId, jwt: jwt)
            
            if userDeletionSuccess {
                // Step 3: Clear local data
                await MainActor.run {
                    self.authState = AuthState(jwt: nil, userId: nil, firstName: nil)
                    self.saveAuthStateToUserDefaults(jwt: nil, userId: nil, firstName: nil)
                }
                
                let deletionSummary = deletionResults.map { "\($0.collection): \($0.success ? "✅" : "❌")" }.joined(separator: "\n")
                return (true, "Account deleted successfully!\n\nData deletion summary:\n\(deletionSummary)\n\nPlease also delete your data from Apple Health settings.")
            } else {
                throw NSError(domain: "AuthRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to delete user account"])
            }
            
        } catch {
            return (false, "Account deletion failed: \(error.localizedDescription)")
        }
    }
    
    /// Delete all user data from Strapi collections
    private func deleteAllUserData(userId: String, jwt: String) async -> [DeletionResult] {
        // First, get user profile with all populated relations to see what collections have user data
        guard let userCollections = await getUserCollectionsWithData(userId: userId, jwt: jwt) else {
            return [DeletionResult(collection: "user-profile", success: false)]
        }
        
        var results: [DeletionResult] = []
        
        for collection in userCollections {
            let success = await deleteUserDataFromCollection(collection: collection, userId: userId, jwt: jwt)
            results.append(DeletionResult(collection: collection, success: success))
        }
        
        return results
    }
    
    /// Get all collections where the user has data by fetching user/me with populate=*
    private func getUserCollectionsWithData(userId: String, jwt: String) async -> [String]? {
        guard let url = URL(string: "\(baseURL)users/me?populate=*") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch user profile: \(response)")
                return nil
            }
            
            // Parse the response to extract collections with user data
            let userData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let collections = extractCollectionsFromUserData(userData)
            
            print("Found user data in collections: \(collections)")
            return collections
            
        } catch {
            print("Error fetching user collections: \(error)")
            return nil
        }
    }
    
    /// Extract collection names from populated user data
    private func extractCollectionsFromUserData(_ userData: [String: Any]?) -> [String] {
        guard let userData = userData else { return [] }
        
        var collections: Set<String> = []
        
        // Check for common user data fields
        let userDataFields = [
            "health_vitals", "health_logs", "sleeplogs", "workout_logs", "meallogs",
            "challenges", "packs", "posts", "friends", "periods", "period_symptoms",
            "fitcoin_logs", "step_sessions", "meal_feedbacks", "mini_forums",
            "diet_logs", "comments", "cheers", "weight_loss_stories", "daily_quests"
        ]
        
        for field in userDataFields {
            if let fieldData = userData[field] {
                // If the field has data (not null/empty), add to collections
                if let array = fieldData as? [Any], !array.isEmpty {
                    collections.insert(field.replacingOccurrences(of: "_", with: "-"))
                } else if fieldData is [String: Any] {
                    collections.insert(field.replacingOccurrences(of: "_", with: "-"))
                }
            }
        }
        
        // Also check for any other populated relations
        for (key, value) in userData {
            if key != "id" && key != "email" && key != "firstName" && key != "lastName" && 
               key != "createdAt" && key != "updatedAt" && key != "publishedAt" {
                if let array = value as? [Any], !array.isEmpty {
                    collections.insert(key.replacingOccurrences(of: "_", with: "-"))
                } else if value is [String: Any] {
                    collections.insert(key.replacingOccurrences(of: "_", with: "-"))
                }
            }
        }
        
        return Array(collections)
    }
    
    /// Delete user data from a specific collection
    private func deleteUserDataFromCollection(collection: String, userId: String, jwt: String) async -> Bool {
        // First, fetch all records for this user
        guard let records = await fetchUserRecords(collection: collection, userId: userId, jwt: jwt) else {
            return false
        }
        
        // Delete each record
        for record in records {
            let success = await deleteRecord(collection: collection, recordId: record.id, jwt: jwt)
            if !success {
                print("Failed to delete \(collection) record \(record.id)")
            }
        }
        
        return true
    }
    
    /// Fetch all records for a user from a specific collection
    private func fetchUserRecords(collection: String, userId: String, jwt: String) async -> [StrapiRecord]? {
        let userFilters = [
            "users_permissions_user": userId,
            "challengerId": userId,
            "challengeeId": userId,
            "userId": userId
        ]
        
        for (field, value) in userFilters {
            if let records = await fetchRecordsWithFilter(collection: collection, field: field, value: value, jwt: jwt) {
                return records
            }
        }
        
        return []
    }
    
    /// Fetch records with a specific filter
    private func fetchRecordsWithFilter(collection: String, field: String, value: String, jwt: String) async -> [StrapiRecord]? {
        guard let url = URL(string: "\(baseURL)\(collection)?filters[\(field)][id][$eq]=\(value)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            guard let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "AuthRepository", code: (httpResponse as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
            }
            
            let strapiResponse = try JSONDecoder().decode(StrapiCollectionResponse.self, from: data)
            return strapiResponse.data
        } catch {
            print("Error fetching \(collection) records: \(error)")
            return nil
        }
    }
    
    /// Delete a specific record from a collection
    private func deleteRecord(collection: String, recordId: Int, jwt: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)\(collection)/\(recordId)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }
            return true
        } catch {
            print("Error deleting \(collection) record \(recordId): \(error)")
            return false
        }
    }
    
    /// Delete the user account from Strapi
    private func deleteUserAccount(userId: String, jwt: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)users/\(userId)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }
            return true
        } catch {
            print("Error deleting user account: \(error)")
            return false
        }
    }
    
    // MARK: - TokenManager Implementation
    
    var currentToken: String? {
        return authState.jwt
    }
    
    var isStravaConnected: Bool {
        // For now, return false. This should be updated when Strava integration is implemented
        return false
    }
    
    func refreshTokenIfNeeded() async throws {
        // For now, we'll just check if the token exists
        // In a real implementation, you might want to validate the token with the server
        guard let _ = authState.jwt else {
            throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No token available"])
        }
    }
    
    func updateUserName(_ newName: String) {
        Task { @MainActor in
            self.authState = AuthState(jwt: self.authState.jwt, userId: self.authState.userId, firstName: newName)
            self.saveAuthStateToUserDefaults(jwt: self.authState.jwt, userId: self.authState.userId, firstName: newName)
            print("Updated userName to \(newName)")
        }
    }
    
    private func refreshLogin() async {
        guard let jwt = authState.jwt, let userId = authState.userId else { return }
        
        guard let url = URL(string: "\(baseURL)users/\(userId)") else {
            print("Invalid refresh URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Refresh login failed: \(response)")
                return
            }
            
            let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
            let strapiFirstName = userProfile.firstName ?? "User"
            
            await MainActor.run {
                self.authState = AuthState(jwt: jwt, userId: userId, firstName: strapiFirstName)
                self.saveAuthStateToUserDefaults(jwt: jwt, userId: userId, firstName: strapiFirstName)
            }
        } catch {
            print("Error refreshing login: \(error)")
        }
    }
    
    // MARK: - Strapi Models
    
    struct LoginResponse: Codable {
        let message: String?
        let jwt: String
        let user: User
        
        struct User: Codable {
            let id: Int
            let email: String
            let firstName: String?
        }
    }
    
    struct UserProfile: Codable {
        let id: Int
        let email: String
        let firstName: String?
    }
}

// MARK: - Account Deletion Supporting Models

struct DeletionResult {
    let collection: String
    let success: Bool
}

struct StrapiRecord: Codable {
    let id: Int
    let documentId: String
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
}

struct StrapiCollectionResponse: Codable {
    let data: [StrapiRecord]
    let meta: StrapiMeta?
    
    struct StrapiMeta: Codable {
        let pagination: StrapiPagination?
        
        struct StrapiPagination: Codable {
            let page: Int
            let pageSize: Int
            let pageCount: Int
            let total: Int
        }
    }
}
