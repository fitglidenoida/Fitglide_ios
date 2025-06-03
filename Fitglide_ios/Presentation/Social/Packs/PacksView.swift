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

    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                theme.background
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading packs...")
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                            .scaleEffect(1.5)
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
                } else if viewModel.packs.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 80))
                            .foregroundColor(theme.primary.opacity(0.2))
                        Text("No packs found")
                            .foregroundColor(theme.onSurfaceVariant)
                            .font(FitGlideTheme.titleLarge)
                            .padding(.top, 16)
                        Text("Tap + to create your first pack!")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        Spacer()
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.packs, id: \.id) { pack in
                                NavigationLink(value: pack) {
                                    PackCardView(pack: pack, theme: theme)
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(animateCards ? 1.0 : 0.95)
                                .opacity(animateCards ? 1.0 : 0.0)
                                .onAppear {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(viewModel.packs.firstIndex(where: { $0.id == pack.id }) ?? 0) * 0.05)) {
                                        animateCards = true
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                FloatingActionButton(theme: theme, action: {
                    showCreatePack = true
                })
                .padding(24)
            }
            .navigationTitle("Your Packs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PackEntry.self) { pack in
                let detailVM = PackDetailViewModel(
                    strapiRepository: viewModel.strapiRepository,
                    authRepository: viewModel.authRepository,
                    pack: pack
                )
                PackDetailView(viewModel: detailVM)
            }
            .task {
                await viewModel.fetchPacks()
                animateCards = false // Reset animation on reload
            }
            .sheet(isPresented: $showCreatePack) {
                CreatePackView(viewModel: viewModel)
            }
        }
    }
}

struct PackCardView: View {
    let pack: PackEntry
    let theme: FitGlideTheme.Colors

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Group {
                if let logoUrl = pack.logo?.url, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            defaultAvatar
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    defaultAvatar
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(theme.primary, lineWidth: 2)
            )
            .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(pack.name)
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(theme.onSurface)
                    .lineLimit(1)

                if let description = pack.description {
                    Text(description)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundColor(theme.tertiary)
                        .font(.system(size: 16, weight: .medium))
                    Text("Goal: \(pack.goal) pts")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                }

                ProgressView(value: Float(pack.progress), total: Float(pack.goal))
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                    .frame(height: 8)
                    .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(theme.onSurfaceVariant, lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
    
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .top, endPoint: .bottom)
                )

            Text(String(pack.name.prefix(1).uppercased()))
                .font(FitGlideTheme.titleMedium.bold())
                .foregroundColor(theme.onPrimary)
        }
    }
}

struct FloatingActionButton: View {
    let theme: FitGlideTheme.Colors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.onPrimary)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .top, endPoint: .bottom)
                )
                .clipShape(Circle())
                .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4) // Vibrant shadow
        }
        .buttonStyle(.plain)
    }
}
