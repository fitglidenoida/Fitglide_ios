//
//  ChallengeDetailView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct ChallengeDetailView: View {
    @ObservedObject var viewModel: ChallengeDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var animateContent = false

    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }

    private var statusColor: Color {
        guard let status = viewModel.challenge.challengeStatus?.lowercased() else { return theme.primary }
        switch status {
        case "ongoing": return theme.primary
        case "completed": return theme.quaternary
        case "failed": return theme.tertiary
        default: return theme.secondary
        }
    }

    private var typeIcon: String {
        switch viewModel.challenge.type.lowercased() {
        case "daily": return "calendar.day.timeline.left"
        case "weekly": return "calendar"
        case "streak": return "flame"
        default: return "flag"
        }
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: typeIcon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(statusColor)

                            Text(viewModel.challenge.type.capitalized)
                                .font(FitGlideTheme.titleLarge)
                                .foregroundColor(theme.onSurface)
                        }

                        if let status = viewModel.challenge.challengeStatus {
                            Text("Status: \(status.capitalized)")
                                .font(FitGlideTheme.bodyLarge)
                                .foregroundColor(statusColor)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(statusColor.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if let winner = viewModel.challenge.winner {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(theme.quaternary)
                                Text("Winner: \(winner)")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.quaternary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)

                    // Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Challenge Details")
                            .font(FitGlideTheme.titleMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                            .padding(.bottom, 4)

                        infoRow(icon: "target", label: "Goal: \(viewModel.challenge.goal)")
                        infoRow(icon: "figure.walk", label: "Metric: \(viewModel.challenge.metric ?? "-")")
                        infoRow(icon: "calendar", label: viewModel.formattedDateRange)
                        infoRow(icon: "clock", label: viewModel.durationText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)

                    // Participants Section
                    if let participants = viewModel.challenge.participants, !participants.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Participants")
                                .font(FitGlideTheme.titleMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                                .padding(.bottom, 4)

                            ForEach(participants, id: \.id) { user in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(theme.primary.opacity(0.8))
                                        .font(.system(size: 24))

                                    Text(user.id)
                                        .font(FitGlideTheme.bodyMedium)
                                        .foregroundColor(theme.onSurface)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
                    } else if let pack1 = viewModel.challenge.challengerPack?.id,
                              let pack2 = viewModel.challenge.challengeePack?.id {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pack Challenge")
                                .font(FitGlideTheme.titleMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                                .padding(.bottom, 4)

                            HStack(spacing: 16) {
                                Text(pack1)
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurface)
                                    .padding(8)
                                    .background(theme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Image(systemName: "bolt.horizontal.fill")
                                    .foregroundColor(theme.tertiary)

                                Text(pack2)
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurface)
                                    .padding(8)
                                    .background(theme.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
                    }
                }
                .padding()
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        animateContent = true
                    }
                }
            }
        }
        .navigationTitle("Challenge Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 24)
            Text(label)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
        }
    }
}
