//
//  CreateChallengeViewModel.swift  .swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

class CreateChallengeViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var type: String = "Solo"
    @Published var goal: Int = 10000
    @Published var metric: String = "steps"
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @Published var challengeeEmail: String = ""
    @Published var challengeePackId: String? = nil // 👈 used consistently
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var success = false
    @Published var selectedPackId: String?

    let allowedTypes = ["Solo", "Pack", "PackVsPack", "Public"]

    let metricsByType: [String: [String]] = [
        "Solo": ["steps", "calories", "distance", "weightloss"],
        "Pack": ["steps", "calories", "reps"],
        "PackVsPack": ["steps", "distance"],
        "Public": ["steps", "duration"]
    ]

    var availableMetrics: [String] {
        metricsByType[type] ?? []
    }

    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository

    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.metric = availableMetrics.first ?? "steps"
    }

    @MainActor
    func createChallenge() async {
        guard let challengerId = authRepository.authState.userId else {
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startDateString = formatter.string(from: startDate)
        let endDateString = formatter.string(from: endDate)

        let request = ChallengeRequest(
            goal: goal,
            type: type,
            challenge_status: "pending",
            winner: nil,
            challenger_user: UserId(id: challengerId),
            challengee_user: challengeeEmail.isEmpty ? nil : UserId(id: challengeeEmail),
            challenger_pack: nil,
            challengee_pack: challengeePackId != nil ? PackId(id: challengeePackId!) : nil, // ✅ fixed here
            participants: nil,
            startDate: startDateString,
            endDate: endDateString,
            metric: metric
        )

        do {
            _ = try await strapiRepository.postChallenge(request: request)
            success = true
        } catch {
            errorMessage = "Challenge creation failed: \(error.localizedDescription)"
        }
    }
}
