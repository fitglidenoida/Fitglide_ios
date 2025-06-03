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
}
