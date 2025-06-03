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

class AuthRepository: ObservableObject {
    struct AuthState {
        let jwt: String?
        let userId: String?
        let firstName: String? // ✅ Fetched from Strapi

        var isLoggedIn: Bool { jwt != nil }
    }

    @Published var authState: AuthState
    private let appleAuthManager: AppleAuthManager
    private let userDefaults: UserDefaults
    private let baseURL = "https://admin.fitglide.in/api/"

    init(appleAuthManager: AppleAuthManager = AppleAuthManager(), userDefaults: UserDefaults = UserDefaults.standard) {
        self.appleAuthManager = appleAuthManager
        self.userDefaults = userDefaults
        
        let jwt = userDefaults.string(forKey: "jwt")
        let userId = userDefaults.string(forKey: "userId")
        let firstName = userDefaults.string(forKey: "firstName")
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
                self.authState = AuthState(jwt: jwt, userId: strapiUserId, firstName: strapiFirstName)
                self.saveAuthStateToUserDefaults(jwt: jwt, userId: strapiUserId, firstName: strapiFirstName)
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
            self.authState = AuthState(jwt: nil, userId: nil, firstName: nil)
            self.saveAuthStateToUserDefaults(jwt: nil, userId: nil, firstName: nil)
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
