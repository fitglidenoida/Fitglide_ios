//
//  ChallengeDetailViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

class ChallengeDetailViewModel: ObservableObject {
    @Published var challenge: ChallengeEntry

    let strapiRepository: StrapiRepository
    let authRepository: AuthRepository

    init(
        strapiRepository: StrapiRepository,
        authRepository: AuthRepository,
        challenge: ChallengeEntry
    ) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.challenge = challenge
    }

    var durationText: String {
        guard let start = isoDate(from: challenge.startDate), let end = isoDate(from: challenge.endDate) else {
            return "-"
        }
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return "\(components.day ?? 0) days"
    }

    var formattedDateRange: String {
        guard let start = isoDate(from: challenge.startDate), let end = isoDate(from: challenge.endDate) else {
            return "-"
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        return "\(df.string(from: start)) → \(df.string(from: end))"
    }

    private func isoDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
