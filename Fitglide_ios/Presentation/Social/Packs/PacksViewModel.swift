//
//  PacksViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI
import Combine

class PacksViewModel: ObservableObject {
    @Published var packs: [PackEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    
   let strapiRepository: StrapiRepository
   let authRepository: AuthRepository

    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        

        Task {
            await fetchPacks()
        }
    }
    
    @MainActor
    func fetchPacks() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let userId = authRepository.authState.userId else {
                errorMessage = "User not logged in"
                isLoading = false
                return
            }
            let response = try await strapiRepository.getPacks(userId: userId)
            self.packs = response.data
        } catch {
            print("Error fetching packs: \(error.localizedDescription)")
            errorMessage = "Failed to load packs."
        }

        isLoading = false
    }
    
    @MainActor
    func createPack(name: String, description: String, goal: Int, isPublic: Bool) async throws {
        guard let userId = authRepository.authState.userId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let request = PackRequest(
            name: name,
            goal: goal,
            gliders: [UserId(id: userId)],
            captain: UserId(id: userId),
            description: description.isEmpty ? nil : description,
            visibility: isPublic ? "public" : "private",
            logo: nil
        )
        
        _ = try await strapiRepository.postPack(request: request)
        await fetchPacks()
    }
    
    @MainActor
    func joinPack(packId: Int) async {
        do {
            guard let userId = authRepository.authState.userId else {
                errorMessage = "User not logged in"
                return
            }
            
            // Add user to pack
            let request = PackJoinRequest(
                packId: packId,
                userId: userId
            )
            
            _ = try await strapiRepository.joinPack(request: request)
            
            // Refresh packs to show updated member count
            await fetchPacks()
            
        } catch {
            errorMessage = "Failed to join pack: \(error.localizedDescription)"
        }
    }
}
