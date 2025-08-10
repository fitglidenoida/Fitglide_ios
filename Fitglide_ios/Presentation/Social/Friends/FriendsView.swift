//
//  FriendsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import SwiftUI

struct FriendsView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var animateContent = false
    @State private var showMotivationalQuote = false
    @State private var selectedTab = 0
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    // MARK: - Helper Properties
    private var friendsMotivationalQuotes: [String] {
        [
            "Friends who sweat together, stay together.",
            "Your fitness journey is better with friends by your side.",
            "Together we are stronger, healthier, and happier.",
            "Build your tribe, inspire each other, grow together.",
            "Friendship is the foundation of a healthy community."
        ]
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
                        // Friends Tab
                        friendsTabContent
                            .tag(0)
                        
                        // Requests Tab
                        requestsTabContent
                            .tag(1)
                        
                        // Suggestions Tab
                        suggestionsTabContent
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                // FAB removed - functionality moved to SocialTabView header
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show motivational quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadFriends()
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Friends & Community 🙏")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Connect, inspire, and grow together")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: { /* Navigate to profile */ }) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(theme.primary)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
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
                
                Text("Community Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(friendsMotivationalQuotes.randomElement() ?? friendsMotivationalQuotes[0])
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
            ForEach(["Friends", "Requests", "Suggestions"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = ["Friends", "Requests", "Suggestions"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                    .font(FitGlideTheme.bodyMedium)
                            .fontWeight(selectedTab == ["Friends", "Requests", "Suggestions"].firstIndex(of: tab) ? .semibold : .medium)
                            .foregroundColor(selectedTab == ["Friends", "Requests", "Suggestions"].firstIndex(of: tab) ? theme.primary : theme.onSurfaceVariant)
                        
                        Rectangle()
                            .fill(selectedTab == ["Friends", "Requests", "Suggestions"].firstIndex(of: tab) ? theme.primary : Color.clear)
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
    
    // MARK: - Friends Tab Content
    var friendsTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    modernLoadingSection
                } else if viewModel.receivedRequests.filter({ $0.friendsStatus == "Accepted" }).isEmpty {
                    modernEmptyState
                } else {
                    // Friends Stats Card
                    friendsStatsCard
                    
                    // Friends List
                    friendsListSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Requests Tab Content
    var requestsTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if viewModel.sentRequests.isEmpty && viewModel.receivedRequests.isEmpty {
                    modernRequestsEmptyState
                } else {
                    // Received Requests
                    if !viewModel.receivedRequests.isEmpty {
                        receivedRequestsSection
                    }
                    
                    // Sent Requests
                    if !viewModel.sentRequests.isEmpty {
                        sentRequestsSection
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Suggestions Tab Content
    var suggestionsTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Invite Friends Section
                inviteFriendsSection
                
                // Suggested Friends will be implemented in future updates
                suggestedFriendsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Friends Stats Card
    var friendsStatsCard: some View {
        HStack(spacing: 16) {
            ModernStatCard(
                title: "Friends",
                value: "\(viewModel.receivedRequests.filter { $0.friendsStatus == "Accepted" }.count)",
                icon: "person.2.fill",
                color: .blue,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.2
            )
            
            ModernStatCard(
                title: "Requests",
                value: "\(viewModel.receivedRequests.filter { $0.friendsStatus == "Pending" }.count)",
                icon: "person.badge.plus",
                color: .orange,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.3
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Friends List Section
    var friendsListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Friends")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(viewModel.receivedRequests.filter { $0.friendsStatus == "Accepted" }.count) friends")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.receivedRequests.filter { $0.friendsStatus == "Accepted" }.enumerated()), id: \.offset) { index, friendEntry in
                    ModernFriendCard(
                        friendEntry: friendEntry,
                        theme: theme,
                        animateContent: $animateContent,
                        delay: 0.4 + Double(index) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Received Requests Section
    var receivedRequestsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Friend Requests")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(viewModel.receivedRequests.count) pending")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.receivedRequests.filter { $0.friendsStatus == "Pending" }.enumerated()), id: \.offset) { index, request in
                    ModernRequestCard(
                        request: request,
                        isReceived: true,
                        onAccept: { Task { await viewModel.respondToFriendRequest(id: request.id, accept: true) } },
                        onDecline: { Task { await viewModel.respondToFriendRequest(id: request.id, accept: false) } },
                        theme: theme,
                        animateContent: $animateContent,
                        delay: 0.4 + Double(index) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Sent Requests Section
    var sentRequestsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sent Requests")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(viewModel.sentRequests.count) sent")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.sentRequests.filter { $0.friendsStatus == "Pending" }.enumerated()), id: \.offset) { index, request in
                    ModernRequestCard(
                        request: request,
                        isReceived: false,
                        onAccept: nil,
                        onDecline: nil,
                        theme: theme,
                        animateContent: $animateContent,
                        delay: 0.4 + Double(index) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Invite Friends Section
    var inviteFriendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Invite Friends")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Enter email address", text: $viewModel.emailToInvite)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.onSurface.opacity(0.1), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                
                Button(action: {
                    Task { await viewModel.sendFriendRequest() }
                }) {
                    Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.onPrimary)
                        .frame(width: 44, height: 44)
                        .background(theme.primary)
                        .clipShape(Circle())
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Suggested Friends Section
    var suggestedFriendsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Suggested Friends")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if viewModel.isLoading {
                modernLoadingSection
            } else if viewModel.receivedRequests.isEmpty {
                modernEmptyState
            } else {
                // Show pending requests as suggestions
                let pendingRequests = viewModel.receivedRequests.filter { $0.friendsStatus == "Pending" }
                if pendingRequests.isEmpty {
                    modernEmptyState
                } else {
                    VStack(spacing: 16) {
                        ForEach(Array(pendingRequests.prefix(3).enumerated()), id: \.element.id) { index, request in
                            suggestedFriendCard(request: request)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Suggested Friend Card
    func suggestedFriendCard(request: FriendEntry) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(theme.surfaceVariant)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.onSurfaceVariant)
                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                Text(request.senderName ?? request.friendEmail)
                                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                                    .foregroundColor(theme.onSurface)
                                
                Text("Wants to connect with you")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
            
            Button("Add") {
                Task {
                    await viewModel.respondToFriendRequest(id: request.id, accept: true)
                }
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
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }

    
    // MARK: - Modern Loading Section
    var modernLoadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.2)
            
            Text("Loading your friends...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Modern Empty State
    var modernEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.2.slash.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Friends Yet")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text("Start building your fitness community by inviting friends to join your wellness journey!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            
            Button("Invite Friends") {
                selectedTab = 2
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
    
    // MARK: - Modern Requests Empty State
    var modernRequestsEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Requests")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text("You don't have any pending friend requests at the moment.")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
    }
    

    

}

// MARK: - Supporting Views

struct ModernStatCard: View {
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

struct ModernFriendCard: View {
    let friendEntry: FriendEntry
        let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
        
        var body: some View {
            HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.primary)
            }
                
                VStack(alignment: .leading, spacing: 4) {
                Text(friendEntry.senderName ?? friendEntry.friendEmail)
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                Text("Active now")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(.green)
                }
                
                Spacer()
            
            Button("Message") {
                // Message action
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
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct ModernRequestCard: View {
    let request: FriendEntry
    let isReceived: Bool
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.senderName ?? request.friendEmail)
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(isReceived ? "Wants to be your friend" : "Request sent")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            if isReceived {
                HStack(spacing: 8) {
                    Button("Accept") {
                        onAccept?()
                    }
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button("Decline") {
                        onDecline?()
                    }
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Text(request.friendsStatus.capitalized)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.surfaceVariant.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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


