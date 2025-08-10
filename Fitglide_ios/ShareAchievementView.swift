//
//  ShareAchievementView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import SwiftUI

struct ShareAchievementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let achievement: Achievement
    let strapiRepository: StrapiRepository
    let userId: String
    
    @State private var selectedShareOption: ShareOption = .friends
    @State private var showChallengeSheet = false
    @State private var showShareSheet = false
    @State private var animateContent = false
    @State private var showMotivationalQuote = false
    @State private var selectedFriends: Set<String> = []
    @State private var selectedPacks: Set<String> = []
    @State private var challengeMessage = ""
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    enum ShareOption: String, CaseIterable {
        case friends = "Friends"
        case packs = "Packs"
        case challenge = "Challenge"
        case social = "Social"
        
        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .packs: return "person.3.fill"
            case .challenge: return "trophy.fill"
            case .social: return "square.and.arrow.up"
            }
        }
        
        var color: Color {
            switch self {
            case .friends: return .blue
            case .packs: return .green
            case .challenge: return .orange
            case .social: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header Section
                        modernHeaderSection
                        
                        // Indian Motivational Quote
                        if showMotivationalQuote {
                            indianMotivationalQuoteCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Achievement Card
                        achievementCard
                        
                        // Share Options
                        shareOptionsSection
                        
                        // Friends & Packs Selection
                        if selectedShareOption == .friends || selectedShareOption == .packs {
                            friendsPacksSelectionSection
                        }
                        
                        // Challenge Section
                        if selectedShareOption == .challenge {
                            challengeSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { shareAchievement() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
                
                // Load friends data
                Task {
                    await loadFriends()
                }
                
                // Show motivational quote after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
            .sheet(isPresented: $showChallengeSheet) {
                createChallengeSheet
            }
            .sheet(isPresented: $showShareSheet) {
                createShareSheet
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Achievement 🏆")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Celebrate your success and inspire others!")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Achievement icon
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Motivational Quote Card
    var indianMotivationalQuoteCard: some View {
        VStack(spacing: 12) {
            Text("""
                "Success is not final, failure is not fatal: it is the courage to continue that counts."
                """)
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(colors.onSurface)
            .multilineTextAlignment(.center)
            
            Text("Ancient Indian Wisdom")
                .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Achievement Card
    var achievementCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Achievement")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(achievement.color)
                }
                
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                    
                    if let progress = achievement.progress {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Progress")
                                    .font(FitGlideTheme.caption)
                                    .foregroundColor(colors.onSurfaceVariant)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(FitGlideTheme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colors.primary)
                            }
                            
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.surface)
                    .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Share Options Section
    var shareOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Share With")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ShareOption.allCases, id: \.self) { option in
                    ModernShareOptionCard(
                        option: option,
                        isSelected: selectedShareOption == option,
                        action: { selectedShareOption = option },
                        theme: colors
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Friends & Packs Selection Section
    var friendsPacksSelectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(selectedShareOption == .friends ? "Select Friends" : "Select Packs")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            // Real friends data from Strapi
            if isLoadingFriends {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                    .padding()
            } else if friends.isEmpty {
                Text("No friends found")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(friends, id: \.id) { friend in
                        ModernFriendPackCard(
                            name: friend.senderName ?? "Friend",
                            avatar: "👤",
                            isSelected: selectedFriends.contains(String(friend.id)),
                            action: {
                                if selectedFriends.contains(String(friend.id)) {
                                    selectedFriends.remove(String(friend.id))
                                } else {
                                    selectedFriends.insert(String(friend.id))
                                }
                            },
                            theme: colors
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Challenge Section
    var challengeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Create Challenge")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                TextField("Enter your challenge message...", text: $challengeMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                
                Text("Challenge your friends to achieve the same goal!")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Quick Actions Section
    var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ModernButton(
                    title: "Share Now",
                    icon: "square.and.arrow.up",
                    style: .primary
                ) {
                    shareAchievement()
                }
                
                ModernButton(
                    title: "Create Challenge",
                    icon: "trophy",
                    style: .secondary
                ) {
                    showChallengeSheet = true
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Challenge Sheet
    var createChallengeSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Challenge")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                
                Text("Challenge your friends to achieve the same goal!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                
                // Challenge options would go here
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showChallengeSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Share Sheet
    var createShareSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Achievement")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                
                Text("Share your achievement with the world!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                
                // Share options would go here
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showShareSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func shareAchievement() {
        // Implementation for sharing achievement
        print("Sharing achievement: \(achievement.title)")
        showShareSheet = true
    }
    
    // MARK: - Real Data
    @State private var friends: [FriendEntry] = []
    @State private var isLoadingFriends = false
    
    private func loadFriends() async {
        isLoadingFriends = true
        do {
            let response = try await strapiRepository.getFriends(filters: [:])
            await MainActor.run {
                self.friends = response.data
                self.isLoadingFriends = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingFriends = false
            }
            print("Failed to load friends: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ModernShareOptionCard: View {
    let option: ShareAchievementView.ShareOption
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? option.color.opacity(0.15) : theme.surfaceVariant.opacity(0.5))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? option.color : theme.onSurfaceVariant)
                }
                
                Text(option.rawValue)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? option.color : theme.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? option.color.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? option.color.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct ModernFriendPackCard: View {
    let name: String
    let avatar: String
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary.opacity(0.15) : theme.surfaceVariant.opacity(0.5))
                        .frame(width: 48, height: 48)
                    
                    Text(avatar)
                        .font(.system(size: 24))
                }
                
                Text(name)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Achievement Extension
extension Achievement {
    var color: Color {
        switch category {
        case .fitness: return .green
        case .nutrition: return .orange
        case .social: return .blue
        case .streak: return .purple
        case .milestone: return .red
        case .wellness: return .teal
        case .challenge: return .indigo
        }
    }
    
    var dateEarned: Date {
        return unlockedDate ?? Date()
    }
}



// MARK: - Preview
#Preview {
    ShareAchievementView(
        achievement: Achievement(
            id: "1",
            title: "5K Runner",
            description: "Completed your first 5K run!",
            icon: "figure.run",
            category: .fitness,
            isUnlocked: true,
            unlockedDate: Date(),
            progress: 1.0,
            target: 5000.0,
            level: 1,
            fitCoinsReward: 100,
            badgeImageName: "5K Runner",
            isHidden: false,
            unlockCondition: "Complete a 5K run"
        ),
        strapiRepository: StrapiRepository(authRepository: AuthRepository()),
        userId: "1"
    )
}
