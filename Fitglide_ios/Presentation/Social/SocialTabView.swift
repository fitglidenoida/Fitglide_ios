//
//  SocialTabView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct SocialTabView: View {
    @State private var selectedTab: Int = 0
    @State private var animateTabs = false
    @State private var showCreatePost = false
    @State private var showNotifications = false
    
    let packsViewModel: PacksViewModel
    let challengesViewModel: ChallengesViewModel
    let friendsViewModel: FriendsViewModel
    let cheersViewModel: CheersViewModel

    @Environment(\.colorScheme) var colorScheme

    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private let tabs = [
        SocialTab(title: "Packs", icon: "person.3.fill", color: .blue),
        SocialTab(title: "Challenges", icon: "trophy.fill", color: .orange),
        SocialTab(title: "Friends", icon: "heart.fill", color: .pink),
        SocialTab(title: "Cheers", icon: "hand.thumbsup.fill", color: .green)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Modern Header with Actions
                ModernSocialHeader(
                    selectedTab: $selectedTab,
                    showCreatePost: $showCreatePost,
                    showNotifications: $showNotifications,
                    theme: theme
                )
                
                // Enhanced Tab Bar with Icons
                SocialModernTabBar(
                    tabs: tabs,
                    selectedTab: $selectedTab,
                    animateTabs: $animateTabs,
                    theme: theme
                )
                
                // Content with Smooth Transitions
                TabView(selection: $selectedTab) {
                    PacksView(viewModel: packsViewModel)
                        .tag(0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    NavigationStack {
                        ChallengesView(viewModel: challengesViewModel)
                    }
                    .tag(1)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    FriendsView(viewModel: friendsViewModel)
                        .tag(2)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                    CheersView(viewModel: cheersViewModel)
                        .tag(3)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: selectedTab)
            }
            .background(theme.background.ignoresSafeArea())
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateTabs = true
                }
            }
        }
    }
}

// MARK: - Modern Social Header
struct ModernSocialHeader: View {
    @Binding var selectedTab: Int
    @Binding var showCreatePost: Bool
    @Binding var showNotifications: Bool
    let theme: FitGlideTheme.Colors
    
    @State private var animateHeader = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Social")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Connect & motivate together")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Notifications Button
                    Button(action: { showNotifications.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(theme.surface)
                                .frame(width: 44, height: 44)
                                .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                            
                            Image(systemName: "bell")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.onSurface)
                        }
                    }
                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: animateHeader)
                    
                    // Create Post Button
                    Button(action: { showCreatePost.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 44, height: 44)
                                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.onPrimary)
                        }
                    }
                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: animateHeader)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 8)
        .background(
            theme.background
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateHeader = true
            }
        }
    }
}

// MARK: - Social Modern Tab Bar with Icons
struct SocialModernTabBar: View {
    let tabs: [SocialTab]
    @Binding var selectedTab: Int
    @Binding var animateTabs: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                SocialModernTabButton(
                    tab: tab,
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            selectedTab = index
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .offset(y: animateTabs ? 0 : 20)
                .opacity(animateTabs ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateTabs)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Social Modern Tab Button
struct SocialModernTabButton: View {
    let tab: SocialTab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tab.color.opacity(0.15) : Color.clear)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? tab.color : theme.onSurfaceVariant)
                }
                
                Text(tab.title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? tab.color : theme.onSurfaceVariant)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Social Tab Model
struct SocialTab {
    let title: String
    let icon: String
    let color: Color
}

#Preview {
    let authRepo = AuthRepository()
    let strapiRepo = StrapiRepository(authRepository: authRepo)
    
    SocialTabView(
        packsViewModel: PacksViewModel(strapiRepository: strapiRepo, authRepository: authRepo),
        challengesViewModel: ChallengesViewModel(strapiRepository: strapiRepo, authRepository: authRepo),
        friendsViewModel: FriendsViewModel(strapiRepository: strapiRepo, authRepository: authRepo),
        cheersViewModel: CheersViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
    )
}
