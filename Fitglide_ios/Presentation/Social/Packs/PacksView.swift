//
//  PacksView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import SwiftUI

struct PacksView: View {
    @ObservedObject var viewModel: PacksViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showCreatePack = false
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
                        // My Packs Tab
                        myPacksTabContent
                            .tag(0)
                        
                        // Discover Packs Tab
                        discoverPacksTabContent
                            .tag(1)
                        
                        // Pack Invites Tab
                        packInvitesTabContent
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                // FAB removed - functionality moved to SocialTabView header
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
            .navigationDestination(for: PackEntry.self) { pack in
                let detailVM = PackDetailViewModel(
                    strapiRepository: viewModel.strapiRepository,
                    authRepository: viewModel.authRepository,
                    pack: pack
                )
                PackDetailView(viewModel: detailVM)
            }
            .sheet(isPresented: $showCreatePack) {
                CreatePackView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchPacks()
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wolf Packs 🐺")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateCards ? 0 : -20)
                        .opacity(animateCards ? 1.0 : 0.0)
                    
                    Text("Lead your pack, inspire your gliders")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateCards ? 0 : -20)
                        .opacity(animateCards ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Pack Stats Button
                Button(action: { /* Show pack stats */ }) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "chart.bar.fill")
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
                
                Text("Pack Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(packsMotivationalQuotes.randomElement() ?? packsMotivationalQuotes[0])
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
            ForEach(["My Packs", "Discover", "Invites"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = ["My Packs", "Discover", "Invites"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(selectedTab == ["My Packs", "Discover", "Invites"].firstIndex(of: tab) ? .semibold : .medium)
                            .foregroundColor(selectedTab == ["My Packs", "Discover", "Invites"].firstIndex(of: tab) ? theme.primary : theme.onSurfaceVariant)
                        
                        Rectangle()
                            .fill(selectedTab == ["My Packs", "Discover", "Invites"].firstIndex(of: tab) ? theme.primary : Color.clear)
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
    
    // MARK: - My Packs Tab Content
    var myPacksTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if viewModel.isLoading {
                    modernLoadingSection
                } else if viewModel.errorMessage != nil {
                    modernErrorSection
                } else if viewModel.packs.isEmpty {
                    modernEmptyState
                } else {
                    // Pack Stats Overview
                    packStatsOverview
                    
                    // Packs List
                    packsListSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Discover Packs Tab Content
    var discoverPacksTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Discover Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Discover Packs")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                    }
                    
                    Text("Find amazing packs to join and grow with")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                // Featured Packs (placeholder)
                featuredPacksSection
                
                // Popular Packs (placeholder)
                popularPacksSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Pack Invites Tab Content
    var packInvitesTabContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Invites Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Pack Invites")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                    }
                    
                    Text("You have 0 pending pack invitations")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                // Empty invites state
                modernInvitesEmptyState
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Pack Stats Overview
    var packStatsOverview: some View {
        let captainPacksCount = viewModel.packs.filter { $0.captain?.id == viewModel.authRepository.authState.userId }.count
        
        return HStack(spacing: 16) {
            ModernPackStatCard(
                title: "My Packs",
                value: "\(viewModel.packs.count)",
                icon: "person.3.fill",
                color: .blue,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.2
            )
            
            ModernPackStatCard(
                title: "As Captain",
                value: "\(captainPacksCount)",
                icon: "crown.fill",
                color: .yellow,
                theme: theme,
                animateContent: $animateCards,
                delay: 0.3
            )
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
    }
    
    // MARK: - Packs List Section
    var packsListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Packs")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(viewModel.packs.count) packs")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.packs.enumerated()), id: \.offset) { index, pack in
                    NavigationLink(value: pack) {
                        ModernPackCard(
                            pack: pack,
                            theme: theme,
                            animateContent: $animateCards,
                            delay: 0.4 + Double(index) * 0.1,
                            currentUserId: viewModel.authRepository.authState.userId
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateCards)
    }
    
    // MARK: - Featured Packs Section
    var featuredPacksSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Featured Packs")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if viewModel.isLoading {
                modernLoadingSection
            } else if viewModel.packs.isEmpty {
                modernEmptyState
            } else {
                // Show public packs as featured
                let publicPacks = viewModel.packs.filter { $0.visibility == "public" }
                if publicPacks.isEmpty {
                    modernEmptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(publicPacks.prefix(3), id: \.id) { pack in
                            featuredPackCard(pack: pack)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Featured Pack Card
    func featuredPackCard(pack: PackEntry) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.name ?? "Unnamed Pack")
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("\(pack.gliders?.count ?? 0) gliders • \(pack.visibility ?? "private")")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Button("Join") {
                // TODO: Implement join pack functionality
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
    
    // MARK: - Popular Packs Section
    var popularPacksSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Popular Packs")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if viewModel.isLoading {
                modernLoadingSection
            } else if viewModel.packs.isEmpty {
                modernEmptyState
            } else {
                // Show packs with most members as popular
                let sortedPacks = viewModel.packs.sorted { ($0.gliders?.count ?? 0) > ($1.gliders?.count ?? 0) }
                VStack(spacing: 12) {
                    ForEach(sortedPacks.prefix(2), id: \.id) { pack in
                        popularPackCard(pack: pack)
                    }
                }
            }
        }
    }
    
    // MARK: - Popular Pack Card
    func popularPackCard(pack: PackEntry) -> some View {
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
                Text(pack.name ?? "Unnamed Pack")
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("\(pack.gliders?.count ?? 0) gliders • Popular")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Button("Join") {
                // TODO: Implement join pack functionality
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
    
    // MARK: - Modern Loading Section
    var modernLoadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.2)
            
            Text("Loading your packs...")
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
            
            Text("We couldn't load your packs. Please try again.")
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
                
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Packs Yet")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text("Create your first wolf pack and lead your gliders to fitness success!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Pack") {
                showCreatePack = true
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
    
    // MARK: - Modern Invites Empty State
    var modernInvitesEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 8) {
                Text("No Invites")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text("You don't have any pack invitations at the moment.")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Helper Properties
    private var packsMotivationalQuotes: [String] {
        [
            "A wolf pack is only as strong as its weakest member.",
            "Lead with courage, inspire with passion, grow together.",
            "In unity there is strength, in packs there is power.",
            "Every captain was once a glider, every glider can become a captain.",
            "Together we hunt, together we grow, together we succeed."
        ]
    }
}

// MARK: - Supporting Views

struct ModernPackStatCard: View {
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

struct ModernPackCard: View {
    let pack: PackEntry
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    let currentUserId: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Pack Avatar
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(pack.name)
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    if pack.captain?.id == currentUserId {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("\(pack.gliders?.count ?? 0) gliders")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(pack.description ?? "A fitness pack for motivated individuals")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                    .lineLimit(2)
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
