//
//  PackDetailViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

class PackDetailViewModel: ObservableObject {
    @Published var pack: PackEntry?
    @Published var posts: [PostEntry] = []
    @Published var challenges: [ChallengeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    public let strapiRepository: StrapiRepository
    public let authRepository: AuthRepository

    init(strapiRepository: StrapiRepository, authRepository: AuthRepository, pack: PackEntry) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.pack = pack
    }


    @MainActor
    func loadPackDetails(packId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch pack info (already populated if needed)
            let packsResponse = try await strapiRepository.getPacks(userId: authRepository.authState.userId ?? "")
            self.pack = packsResponse.data.first(where: { $0.id == packId })

            // Fetch posts for this pack
            self.posts = try await strapiRepository.getPosts(packId: packId).data

            // Fetch challenges where this pack is a challengee or challenger
            let allChallenges = try await strapiRepository.getChallenges(userId: authRepository.authState.userId ?? "").data
            self.challenges = allChallenges.filter {
                $0.challengerPack?.id == String(packId) || $0.challengeePack?.id == String(packId)
            }
        } catch {
            print("Failed to load pack details: \(error.localizedDescription)")
            errorMessage = "Could not load pack info."
        }
    }
}
