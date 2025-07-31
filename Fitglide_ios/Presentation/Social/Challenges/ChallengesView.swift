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
    @State private var showMotivationalQuote = false
    @State private var selectedTab = 0
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        theme.background,
                        theme.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header Section
                    modernHeaderSection
                    
                    // Motivational Quote (Indian focused)
                    if showMotivationalQuote {
                        indianMotivationalQuoteCard
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    
                    // Tab Selector
                    modernTabSelector
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        // Active Challenges Tab
                        activeChallengesTabContent
                            .tag(0)
                        
                        // Community Challenges Tab
                        communityChallengesTabContent
                            .tag(1)
                        
                        // My Challenges Tab
                        myChallengesTabContent
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                // FAB for Create Challenge
                VStack(spacing: 16) {
                    if showFABMenu {
                        quickActionButtons
                    }
                    
                    fabButton
                }
                .padding(24)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateCards = true
                }
                
                // Show motivational quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateChallenge) {
                if let createVM = createChallengeViewModel {
                    CreateChallengeView(viewModel: createVM, onDismiss: {
                        showCreateChallenge = false
                    })
                }
            }
            .task {
                await viewModel.loadChallenges()
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fitness Challenges 🏆")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateCards ? 0 : -20)
                        .opacity(animateCards ? 1.0 : 0.0)
                    
                    Text("Push your limits, inspire others, win together")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateCards ? 0 : -20)
                        .opacity(animateCards ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Challenge Stats Button
                Button(action: { /* Show challenge stats */ }) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.primary)
                    }
                }
                .scaleEffect(animateCards ? 1.0 : 0.8)
                .opacity(animateCards ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            theme.background
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Motivational Quote Card
    var indianMotivationalQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                Text("Challenge Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(challengesMotivationalQuotes.randomElement() ?? challengesMotivationalQuotes[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
            .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Modern Tab Selector
    var modernTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Active", "Community", "My Challenges"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = ["Active", "Community", "My Challenges"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(selectedTab == ["Active", "Community", "My Challenges"].firstIndex(of: tab) ? .semibold : .medium)
                            .foregroundColor(selectedTab == ["Active", "Community", "My Challenges"].firstIndex(of: tab) ? theme.primary : theme.onSurfaceVariant)
                        
                        Rectangle()
                            .fill(selectedTab == ["Active", "Community", "My Challenges"].firstIndex(of: tab) ? theme.primary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Active Challenges Tab Content
    var activeChallengesTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    modernLoadingSection
                } else if let error = viewModel.errorMessage {
                    modernErrorSection
                } else if viewModel.challenges.isEmpty {
                    modernEmptyState
                } else {
                    // Challenge Stats Overview
                    challengeStatsOverview
                    
                    // Active Challenges List
                    activeChallengesListSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Community Challenges Tab Content
    var communityChallengesTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Community Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Community Challenges")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                    Spacer()
                    }
                    
                    Text("Join global fitness challenges and compete with the world")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                // Featured Community Challenges
                featuredCommunityChallengesSection
                
                // Trending Challenges
                trendingChallengesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - My Challenges Tab Content
    var myChallengesTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // My Challenges Header
                VStack(spacing: 16) {
                    HStack {
                        Text("My Challenges")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                    Spacer()
                }
                    
                    Text("Track your personal fitness journey and achievements")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                // Personal Challenge Stats
                personalChallengeStatsSection
                
                // My Challenges List
                myChallengesListSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Challenge Stats Overview
    var challengeStatsOverview: some View {
        HStack(spacing: 16) {
            ModernChallengeStatCard(
                title: "Active",
                value: "\(viewModel.challenges.filter { $0.challengeStatus?.lowercased() == "ongoing" }.count)",
                icon: "flame.fill",
                color: .orange,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.2
            )
            
            ModernChallengeStatCard(
                title: "Completed",
                value: "\(viewModel.challenges.filter { $0.challengeStatus?.lowercased() == "completed" }.count)",
                icon: "checkmark.circle.fill",
                color: .green,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.3
            )
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
    }
    
    // MARK: - Active Challenges List Section
    var activeChallengesListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Challenges")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                    Spacer()
                
                Text("\(viewModel.challenges.filter { $0.challengeStatus?.lowercased() == "ongoing" }.count) ongoing")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.challenges.filter { $0.challengeStatus?.lowercased() == "ongoing" }.enumerated()), id: \.offset) { index, challenge in
                    ModernChallengeCard(
                        challenge: challenge,
                        theme: theme,
                        animateContent: $animateCards,
                        delay: 0.4 + Double(index) * 0.1
                    )
                }
            }
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateCards)
    }
    
    // MARK: - Featured Community Challenges Section
    var featuredCommunityChallengesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Featured Challenges")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            // Placeholder for featured community challenges
            VStack(spacing: 12) {
                featuredChallengeCard(index: 0)
                featuredChallengeCard(index: 1)
                featuredChallengeCard(index: 2)
            }
        }
    }
    
    // MARK: - Featured Challenge Card
    func featuredChallengeCard(index: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: challengeIcons[index % challengeIcons.count])
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Featured Challenge \(index + 1)")
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("\(1000 + index * 500) participants • Global")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Button("Join") {
                // Join challenge action
            }
            .font(FitGlideTheme.caption)
            .fontWeight(.medium)
            .foregroundColor(theme.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Trending Challenges Section
    var trendingChallengesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trending Now")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            // Placeholder for trending challenges
            VStack(spacing: 12) {
                trendingChallengeCard(index: 0)
                trendingChallengeCard(index: 1)
            }
        }
    }
    
    // MARK: - Trending Challenge Card
    func trendingChallengeCard(index: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.secondary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Trending Challenge \(index + 1)")
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("\(5000 + index * 1000) participants • Hot")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Button("Join") {
                // Join challenge action
            }
            .font(FitGlideTheme.caption)
            .fontWeight(.medium)
            .foregroundColor(theme.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(theme.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Personal Challenge Stats Section
    var personalChallengeStatsSection: some View {
        HStack(spacing: 16) {
            ModernChallengeStatCard(
                title: "Won",
                value: "12",
                icon: "trophy.fill",
                color: .yellow,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.2
            )
            
            ModernChallengeStatCard(
                title: "Streak",
                value: "7",
                icon: "flame.fill",
                color: .orange,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.3
            )
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
    }
    
    // MARK: - My Challenges List Section
    var myChallengesListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Challenges")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(viewModel.challenges.count) total")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.challenges.enumerated()), id: \.offset) { index, challenge in
                    ModernChallengeCard(
                        challenge: challenge,
                        theme: theme,
                        animateContent: $animateCards,
                        delay: 0.4 + Double(index) * 0.1
                    )
                }
            }
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateCards)
    }
    
    // MARK: - Modern Loading Section
    var modernLoadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.2)
            
            Text("Loading challenges...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Modern Error Section
    var modernErrorSection: some View {
            VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.red)
            }
            
            Text("Oops! Something went wrong")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            Text("We couldn't load your challenges. Please try again.")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Modern Empty State
    var modernEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flag.filled.and.flag.crossed")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Active Challenges")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text("Start your fitness journey by joining or creating a challenge!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Challenge") {
                showCreateChallenge = true
            }
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(theme.onPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 60)
    }
    
    // MARK: - Quick Action Buttons
    var quickActionButtons: some View {
        VStack(spacing: 12) {
                    Button(action: {
                        showCreateChallenge = true
                    }) {
                        HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.onPrimary)
                            Text("Create Challenge")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onPrimary)
                        }
                .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(showFABMenu ? 1 : 0.5)
                    .opacity(showFABMenu ? 1 : 0)
                    .transition(.scale.combined(with: .opacity))
        }
                }
                
    // MARK: - FAB Button
    var fabButton: some View {
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
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                        )
                        .clipShape(Circle())
                .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                        .rotationEffect(.degrees(showFABMenu ? 45 : 0))
                }
            }
    
    // MARK: - Helper Properties
    private var challengesMotivationalQuotes: [String] {
        [
            "Every challenge is an opportunity to become stronger.",
            "Push your limits, discover your potential, inspire others.",
            "The only impossible journey is the one you never begin.",
            "Challenges are what make life interesting, overcoming them is what makes life meaningful.",
            "Your greatest challenge is the one you create for yourself."
        ]
    }
    
    private var challengeIcons: [String] {
        ["flame.fill", "trophy.fill", "star.fill", "bolt.fill", "heart.fill"]
    }
}

// MARK: - Supporting Views

struct ModernChallengeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct ModernChallengeCard: View {
        let challenge: ChallengeEntry
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    private var statusColor: Color {
        guard let status = challenge.challengeStatus?.lowercased() else { return theme.primary }
        switch status {
        case "ongoing": return theme.primary
        case "completed": return .green
        case "failed": return .red
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
            // Challenge Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: typeIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(challenge.type.capitalized)
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    if challenge.challengeStatus?.lowercased() == "ongoing" {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Text("Goal: \(challenge.goal) \(challenge.metric ?? "units")")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                if let status = challenge.challengeStatus {
                    Text(status.capitalized)
                        .font(FitGlideTheme.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text("View")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}
