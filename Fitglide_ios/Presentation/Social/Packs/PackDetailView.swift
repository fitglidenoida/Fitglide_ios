//
//  PackDetailView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct PackDetailView: View {
    @ObservedObject var viewModel: PackDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showFABMenu = false
    @State private var showCreatePost = false
    @State private var postViewModel: CreatePostViewModel? = nil
    @State private var challengeViewModel: CreateChallengeViewModel? = nil
    @State private var animateSections = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            theme.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 24) {
                    packHeaderSection
                        .scaleEffect(animateSections ? 1.0 : 0.95)
                        .opacity(animateSections ? 1.0 : 0.0)
                    
                    postSection
                        .scaleEffect(animateSections ? 1.0 : 0.95)
                        .opacity(animateSections ? 1.0 : 0.0)
                    
                    challengeSection
                        .scaleEffect(animateSections ? 1.0 : 0.95)
                        .opacity(animateSections ? 1.0 : 0.0)
                }
                .padding()
            }
            .refreshable {
                if let id = viewModel.pack?.id {
                    await viewModel.loadPackDetails(packId: id)
                }
            }
            
            fabMenu
                .padding(24)
        }
        .navigationTitle(viewModel.pack?.name ?? "Pack")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let id = viewModel.pack?.id {
                await viewModel.loadPackDetails(packId: id)
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateSections = true
            }
        }
        .sheet(item: $postViewModel) { vm in
            CreatePostView(viewModel: vm)
        }
        .sheet(item: $challengeViewModel) { vm in
            CreateChallengeView(viewModel: vm) {
                challengeViewModel = nil
            }
        }
        .onDisappear {
            animateSections = false
        }
    }
    
    // MARK: - Sections
    
    private var packHeaderSection: some View {
        Group {
            if let pack = viewModel.pack {
                VStack(spacing: 16) {
                    PackHeaderCard(pack: pack, theme: theme)
                    MemberListView(members: pack.gliders ?? [], theme: theme)
                }
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            }
        }
    }
    
    private var postSection: some View {
        Group {
            if !viewModel.posts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Recent Posts", theme: theme)
                    
                    ForEach(viewModel.posts, id: \.id) { post in
                        PostCard(post: post, theme: theme)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
    }
    
    private var challengeSection: some View {
        Group {
            if !viewModel.challenges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Active Challenges", theme: theme)
                    
                    ForEach(viewModel.challenges, id: \.id) { challenge in
                        ChallengeCard(challenge: challenge, theme: theme)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
    }
    
    private var fabMenu: some View {
        VStack(spacing: 16) {
            if showFABMenu {
                Button(action: {
                    let vm = CreatePostViewModel(
                        strapiRepository: viewModel.strapiRepository,
                        authRepository: viewModel.authRepository
                    )
                    vm.selectedPackId = String(viewModel.pack?.id ?? 0)
                    postViewModel = vm
                    withAnimation { showFABMenu = false }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(theme.onPrimary)
                        Text("Post Update")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(showFABMenu ? 1 : 0.5)
                .opacity(showFABMenu ? 1 : 0)
                .transition(.scale.combined(with: .opacity))
                
                Button(action: {
                    let vm = CreateChallengeViewModel(
                        strapiRepository: viewModel.strapiRepository,
                        authRepository: viewModel.authRepository
                    )
                    vm.selectedPackId = String(viewModel.pack?.id ?? 0)
                    challengeViewModel = vm
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
    }
}
