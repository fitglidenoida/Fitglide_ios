//
//  ChallengesView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct ChallengesView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showFABMenu = false
    @State private var showCreateChallenge = false
    @State private var createChallengeViewModel: CreateChallengeViewModel? = nil
    @State private var animateCards = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    struct ChallengeCardCompact: View {
        let challenge: ChallengeEntry
        let theme: FitGlideTheme.Colors
        
        private var statusColor: Color {
            guard let status = challenge.challengeStatus?.lowercased() else { return theme.primary }
            switch status {
            case "ongoing": return theme.primary
            case "completed": return theme.quaternary
            case "failed": return theme.tertiary
            default: return theme.secondary
            }
        }
        
        private var typeIcon: String {
            switch challenge.type.lowercased() {
            case "daily": return "calendar.day.timeline.left"
            case "weekly": return "calendar"
            case "streak": return "flame"
            default: return "flag"
            }
        }
        
        var body: some View {
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: typeIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(statusColor)
                }
                .frame(width: 50, height: 50)
                .background(statusColor.opacity(0.1))
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Type: \(challenge.type.capitalized)")
                        .font(FitGlideTheme.titleMedium)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Goal: \(challenge.goal) • Metric: \(challenge.metric ?? "-")")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    if let status = challenge.challengeStatus {
                        Text("Status: \(status.capitalized)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(statusColor)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            theme.background
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading Challenges...")
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .font(FitGlideTheme.bodyLarge)
                        .foregroundColor(theme.onSurfaceVariant)
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(FitGlideTheme.bodyLarge)
                        .foregroundColor(theme.tertiary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else if viewModel.challenges.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "flag.slash.fill")
                        .font(.system(size: 80))
                        .foregroundColor(theme.primary.opacity(0.2))
                    Text("No challenges found")
                        .foregroundColor(theme.onSurfaceVariant)
                        .font(FitGlideTheme.titleLarge)
                        .padding(.top, 16)
                    Text("Create one to get started!")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.challenges, id: \.id) { challenge in
                            NavigationLink(value: challenge) {
                                ChallengeCardCompact(challenge: challenge, theme: theme)
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(animateCards ? 1 : 0.95)
                            .opacity(animateCards ? 1 : 0)
                            .onAppear {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    animateCards = true
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // FAB and actions
            VStack(spacing: 16) {
                if showFABMenu {
                    Button(action: {
                        let vm = CreateChallengeViewModel(
                            strapiRepository: viewModel.strapiRepository,
                            authRepository: viewModel.authRepository
                        )
                        createChallengeViewModel = vm
                        showCreateChallenge = true
                        withAnimation { showFABMenu = false }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "flag.fill")
                                .foregroundColor(theme.onPrimary)
                            Text("Create Challenge")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onPrimary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(showFABMenu ? 1 : 0.5)
                    .opacity(showFABMenu ? 1 : 0)
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showFABMenu.toggle()
                    }
                }) {
                    Image(systemName: showFABMenu ? "xmark" : "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.onPrimary)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Circle())
                        .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4) // Vibrant shadow
                        .rotationEffect(.degrees(showFABMenu ? 45 : 0))
                }
            }
            .padding(24)
        }
        .navigationDestination(for: ChallengeEntry.self) { challenge in
            ChallengeDetailWrapperView(
                challenge: challenge,
                strapiRepository: viewModel.strapiRepository,
                authRepository: viewModel.authRepository
            )
        }
        .task {
            await viewModel.loadChallenges()
        }
        .sheet(isPresented: $showCreateChallenge) {
            if let vm = createChallengeViewModel {
                CreateChallengeView(viewModel: vm) {
                    showCreateChallenge = false
                    createChallengeViewModel = nil
                    Task {
                        await viewModel.loadChallenges() // Refresh after creation
                    }
                }
            }
        }
    }
    
    struct ChallengeDetailWrapperView: View {
        let challenge: ChallengeEntry
        let strapiRepository: StrapiRepository
        let authRepository: AuthRepository

        var body: some View {
            let viewModel = ChallengeDetailViewModel(
                strapiRepository: strapiRepository,
                authRepository: authRepository,
                challenge: challenge
            )
            ChallengeDetailView(viewModel: viewModel)
        }
    }
}

extension ChallengeEntry: Hashable {
    static func == (lhs: ChallengeEntry, rhs: ChallengeEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
