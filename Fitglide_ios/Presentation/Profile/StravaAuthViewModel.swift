//
//  StravaAuthViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//

import Foundation
import AuthenticationServices
import SwiftUI
import OSLog

@MainActor
class StravaAuthViewModel: NSObject, ObservableObject {
    @Published var isStravaConnected: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let strapiApi: StrapiApi
    private let authRepository: AuthRepository
    private let logger = Logger(subsystem: "com.TrailBlazeWellness.Fitglide-ios", category: "StravaAuthViewModel")
    
    private var authSession: ASWebAuthenticationSession?
    private var csrfState: String?
    
    init(strapiApi: StrapiApi? = nil, authRepository: AuthRepository) {
        self.authRepository = authRepository
        self.strapiApi = strapiApi ?? StrapiApiClient()
        super.init()
        // Check if already connected (e.g., stored access token)
        checkStravaConnection()
    }
    
    func initiateStravaAuth() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    let errorMessage = "Missing user ID for Strava authentication"
                    self.logger.error("\(errorMessage)")
                    self.errorMessage = errorMessage
                    self.isLoading = false
                    return
                }
                
                self.isLoading = true
                self.errorMessage = nil
                
                // Generate CSRF state
                let state = "\(userId):\(UUID().uuidString)"
                self.logger.debug("Generated CSRF state: \(state)")
                self.csrfState = state
                
                guard let token = authRepository.authState.jwt else {
                    let errorMessage = "Missing JWT for Strava authentication"
                    self.logger.error("\(errorMessage)")
                    self.errorMessage = errorMessage
                    self.isLoading = false
                    return
                }
                
                self.logger.debug("Initiating Strava auth with state: \(state)")
                let response = try await strapiApi.initiateStravaAuth(state: state, token: token)
                self.logger.debug("Fetched Strava auth URL: \(response.redirectUrl)")
                
                // Start ASWebAuthenticationSession
                guard let authURL = URL(string: response.redirectUrl) else {
                    let errorMessage = "Invalid Strava auth URL"
                    self.logger.error("\(errorMessage)")
                    self.errorMessage = errorMessage
                    self.isLoading = false
                    return
                }
                
                // Ensure callback scheme matches Info.plist
                let callbackURLScheme = "fitglide.in"
                
                self.authSession = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: callbackURLScheme,
                    completionHandler: { [weak self] callbackURL, error in
                        guard let self = self else { return }
                        
                        Task {
                            self.isLoading = false
                            
                            if let error = error {
                                let errorMessage = "Authentication failed: \(error.localizedDescription)"
                                self.logger.error("\(errorMessage)")
                                self.errorMessage = errorMessage
                                return
                            }
                            
                            guard let callbackURL = callbackURL else {
                                let errorMessage = "No callback URL received"
                                self.logger.error("\(errorMessage)")
                                self.errorMessage = errorMessage
                                return
                            }
                            
                            // Parse callback URL for code and state
                            guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                                  let receivedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
                                  receivedState == self.csrfState else {
                                let errorMessage = "Invalid callback: missing code or state mismatch"
                                self.logger.error("\(errorMessage)")
                                self.errorMessage = errorMessage
                                return
                            }
                            
                            self.logger.debug("Received callback with code: \(code.prefix(10))..., state: \(receivedState)")
                            
                            // Call stravaCallback
                            do {
                                guard let token = self.authRepository.authState.jwt else {
                                    let errorMessage = "Missing JWT for Strava callback"
                                    self.logger.error("\(errorMessage)")
                                    self.errorMessage = errorMessage
                                    return
                                }
                                
                                let callbackRequest = StravaCallbackRequest(code: code, state: receivedState)
                                let callbackResponse = try await self.strapiApi.stravaCallback(request: callbackRequest, token: token)
                                self.logger.debug("Strava callback response: status=\(callbackResponse.status), message=\(callbackResponse.message ?? "nil")")
                                
                                // Exchange code for token
                                let tokenRequest = StravaTokenRequest(code: code)
                                let tokenResponse = try await self.strapiApi.exchangeStravaCode(request: tokenRequest, token: token)
                                self.logger.debug("Received Strava token: accessToken=\(tokenResponse.accessToken.prefix(10))..., athleteID=\(tokenResponse.athlete.id)")
                                
                                // Update connection status
                                self.isStravaConnected = true
                                self.logger.debug("Strava authentication successful")
                            } catch {
                                let errorMessage = "Strava callback failed: \(error.localizedDescription)"
                                self.logger.error("\(errorMessage)")
                                self.errorMessage = errorMessage
                            }
                        }
                    }
                )
                
                // Configure session for iOS 13+ compatibility
                self.authSession?.presentationContextProvider = self
                self.authSession?.prefersEphemeralWebBrowserSession = true
                
                guard self.authSession?.start() == true else {
                    let errorMessage = "Failed to start ASWebAuthenticationSession"
                    self.logger.error("\(errorMessage)")
                    self.errorMessage = errorMessage
                    self.isLoading = false
                    return
                }
                
            } catch {
                self.isLoading = false
                let errorMessage = "Strava authentication failed: \(error.localizedDescription)"
                self.logger.error("\(errorMessage)")
                self.errorMessage = errorMessage
            }
        }
    }
    
    func disconnectStrava() {
        self.logger.debug("Disconnecting Strava")
        self.isStravaConnected = false
        // TODO: Call Strava disconnect API if available
    }
    
    private func checkStravaConnection() {
        self.logger.debug("Checking Strava connection")
        // TODO: Check stored token or API
        self.isStravaConnected = false
    }
}

extension StravaAuthViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Use only iOS 15+ safe window scene API
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }

        // Final fallback if no active window found (unlikely)
        return ASPresentationAnchor()
    }
}

struct Athlete: Codable {
    let id: Int
    let username: String?
    let firstname: String?
    let lastname: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstname
        case lastname
    }
}
