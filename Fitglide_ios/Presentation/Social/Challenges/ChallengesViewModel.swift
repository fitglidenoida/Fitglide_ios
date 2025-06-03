//
//  ChallengesViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

class ChallengesViewModel: ObservableObject {
    @Published var challenges: [ChallengeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    public let strapiRepository: StrapiRepository
    public let authRepository: AuthRepository
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    @MainActor
    func loadChallenges() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = authRepository.authState.userId,
                  let _ = authRepository.authState.jwt else {
                self.errorMessage = "User not logged in"
                return
            }
            
            let response = try await strapiRepository.getChallenges(userId: userId)
            
            // Filter: Only accepted + public
            let allChallenges = response.data
            self.challenges = allChallenges.filter {
                $0.challengeStatus == "accepted" ||
                $0.type.lowercased() == "public"
            }
            
            self.errorMessage = nil
        } catch {
            self.challenges = []
            self.errorMessage = "Failed to load challenges: \(error.localizedDescription)"
        }
    }
}
