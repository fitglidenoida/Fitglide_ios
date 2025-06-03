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
    @State private var showFABMenu = false
    @State private var animateContent = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        inviteSection
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.tertiary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(theme.surfaceVariant.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if viewModel.isLoading {
                            ProgressView("Loading friends...")
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                .padding()
                        } else {
                            if viewModel.sentRequests.isEmpty && viewModel.receivedRequests.isEmpty {
                                emptyState
                            } else {
                                sentRequestsSection
                                receivedRequestsSection
                            }
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
                
                // FAB for Invite
                VStack(spacing: 16) {
                    if showFABMenu {
                        Button(action: {
                            Task { await viewModel.sendFriendRequest() }
                            withAnimation { showFABMenu = false }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundColor(theme.onPrimary)
                                Text("Send Invite")
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
                            .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                            .rotationEffect(.degrees(showFABMenu ? 45 : 0))
                    }
                }
                .padding(24)
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadFriends()
            }
        }
    }
    
    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invite a Friend")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onSurfaceVariant)
            
            HStack(spacing: 12) {
                TextField("Enter email", text: $viewModel.emailToInvite)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(FitGlideTheme.bodyMedium)
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                            .stroke(theme.surfaceVariant, lineWidth: 1)
                    )
                    .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
                
                Button(action: {
                    Task { await viewModel.sendFriendRequest() }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.onPrimary)
                        .frame(width: 44, height: 44)
                        .background(theme.primary)
                        .clipShape(Circle())
                        .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.primary.opacity(0.2))
            Text("No friends yet")
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(theme.onSurfaceVariant)
            Text("Invite someone to get started!")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 40)
    }
    
    private var sentRequestsSection: some View {
        Group {
            if !viewModel.sentRequests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sent Requests")
                        .font(FitGlideTheme.titleMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .padding(.bottom, 4)
                    
                    ForEach(viewModel.sentRequests, id: \.id) { request in
                        HStack(spacing: 16) {
                            AvatarCircle(name: request.friendEmail, theme: theme, imageUrl: nil)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("To: \(request.friendEmail)")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Status: \(request.friendsStatus.capitalized)")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(colorForStatus(request.friendsStatus))
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
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var receivedRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Received Requests")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .padding(.bottom, 4)
            
            ForEach(viewModel.receivedRequests, id: \.id) { request in
                ReceivedRequestRow(request: request, theme: theme) { accept in
                    await viewModel.respondToFriendRequest(id: request.id, accept: accept)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "accepted": return theme.quaternary
        case "pending": return theme.tertiary
        case "rejected": return theme.onSurfaceVariant
        default: return theme.secondary
        }
    }
    
    // MARK: - AvatarCircle
    
    struct AvatarCircle: View {
        let name: String
        let theme: FitGlideTheme.Colors
        let imageUrl: String? // Optional for future support

        var initials: String {
            let components = name.components(separatedBy: " ")
            let first = components.first?.prefix(1) ?? ""
            let last = components.dropFirst().first?.prefix(1) ?? ""
            return (first + last).uppercased()
        }

        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)

                Text(initials)
                    .font(FitGlideTheme.bodyMedium.bold())
                    .foregroundColor(theme.onPrimary)
            }
        }
    }

    // MARK: - ReceivedRequestRow
    
    struct ReceivedRequestRow: View {
        let request: FriendEntry
        let theme: FitGlideTheme.Colors
        let onRespond: (Bool) async -> Void
        
        var body: some View {
            HStack(spacing: 16) {
                AvatarCircle(name: request.senderName ?? "Unknown", theme: theme, imageUrl: nil)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.senderName ?? "Unknown")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Status: \(request.friendsStatus.capitalized)")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colorForStatus(request.friendsStatus))
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            .swipeActions(edge: .trailing) {
                Button {
                    Task { await onRespond(true) }
                } label: {
                    Label("Accept", systemImage: "checkmark")
                }
                .tint(theme.quaternary)
                
                Button(role: .destructive) {
                    Task { await onRespond(false) }
                } label: {
                    Label("Reject", systemImage: "xmark")
                }
                .tint(theme.tertiary)
            }
        }
        
        private func colorForStatus(_ status: String) -> Color {
            switch status.lowercased() {
            case "accepted": return theme.quaternary
            case "pending": return theme.tertiary
            case "rejected": return theme.onSurfaceVariant
            default: return theme.secondary
            }
        }
    }
}
