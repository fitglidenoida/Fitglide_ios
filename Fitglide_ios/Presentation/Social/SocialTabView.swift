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
    let packsViewModel: PacksViewModel
    let challengesViewModel: ChallengesViewModel
    let friendsViewModel: FriendsViewModel
    let cheersViewModel: CheersViewModel

    @Environment(\.colorScheme) var colorScheme

    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    TabButton(
                        title: ["Packs", "Challenges", "Friends", "Cheers"][index],
                        index: index,
                        isSelected: selectedTab == index
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)
            .background(theme.surface)

            Divider()
                .background(theme.surfaceVariant)

            // Content
            TabView(selection: $selectedTab) {
                PacksView(viewModel: packsViewModel)
                    .tag(0)
                NavigationStack {
                    ChallengesView(viewModel: challengesViewModel)
                }
                .tag(1)
                FriendsView(viewModel: friendsViewModel)
                    .tag(2)
                CheersView(viewModel: cheersViewModel)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .background(theme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func TabButton(title: String, index: Int, isSelected: Bool) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Rectangle()
                    .fill(isSelected ? theme.primary : Color.clear)
                    .frame(height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))
            }
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
