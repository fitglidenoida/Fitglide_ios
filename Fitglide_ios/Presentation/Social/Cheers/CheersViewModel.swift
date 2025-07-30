//
//  CheersViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CheersViewModel: ObservableObject {
    @Published var cheersList: [CheerEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var liveWorkoutType: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository

    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        // Live workout tracking moved to Watch app for better performance
    }


    @MainActor
    func loadCheers() async {
        guard let userId = authRepository.authState.userId else {
            errorMessage = "Not logged in"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await strapiRepository.getCheers(userId: userId)
            self.cheersList = response.data
        } catch {
            self.errorMessage = "Failed to load cheers"
        }
    }
}
