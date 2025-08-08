//
//  PackDetailComponents.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct PackHeaderCard: View {
    let pack: PackEntry
    let theme: FitGlideTheme.Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Group {
                    if let urlString = pack.logo?.url, let url = URL(string: urlString) {
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
                                AvatarCircle(name: pack.name, theme: theme, imageUrl: nil)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        AvatarCircle(name: pack.name, theme: theme, imageUrl: nil)
                    }
                }
                .frame(width: 72, height: 72)
                .background(theme.surfaceVariant.opacity(0.5))
                .clipShape(Circle())
                .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(theme.quaternary, lineWidth: 2)
                        .opacity(0.8)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(FitGlideTheme.titleLarge)
                        .foregroundColor(theme.onSurface)
                    Text(pack.description ?? "")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .lineLimit(2)
                    Text("Goal: \(pack.goal) pts")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    ProgressView(value: Float(pack.progress), total: Float(pack.goal))
                        .accentColor(theme.tertiary)
                }
            }
            Text("Visibility: \(pack.visibility ?? "public")")
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(FitGlideTheme.Card.cornerRadius)
        .shadow(radius: FitGlideTheme.Card.elevation)
    }
}

// MemberListView.swift
struct MemberListView: View {
    let members: [UserId]
    let theme: FitGlideTheme.Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Members")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onBackground)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(members, id: \.id) { member in
                        VStack(spacing: 6) {
                            AvatarCircle(
                                name: member.id ?? "Unknown",
                                theme: theme,
                                imageUrl: nil // Replace with actual URL if/when available
                            )
                            Text("ID: \((member.id ?? "Unknown").prefix(4))…")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
    }

    private func initials(for id: String) -> String {
        return String(id.prefix(2)).uppercased()
    }
}

struct AvatarCircle: View {
    let name: String
    let theme: FitGlideTheme.Colors
    let imageUrl: String?

    var initials: String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.primary)
                .frame(width: 48, height: 48)

            Text(initials)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onPrimary)
        }
    }
}


// PostCard.swift
struct PostCard: View {
    let post: PostEntry
    let theme: FitGlideTheme.Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.type.capitalized)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.tertiary)

            Text((post.data["content"]?.value as? String) ?? "")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
                .lineLimit(3)

            Text("Posted on \(post.createdAt.prefix(10))")
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(FitGlideTheme.Card.cornerRadius)
        .shadow(radius: 2)
    }
}

// ChallengeCard.swift
struct ChallengeCard: View {
    let challenge: ChallengeEntry
    let theme: FitGlideTheme.Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(challenge.type)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.primary)

            if let status = challenge.challengeStatus {
                Text("Status: \(status.capitalized)")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            if let metric = challenge.metric {
                Text("Metric: \(metric)")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            if let start = challenge.startDate {
                Text("From \(start)")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(FitGlideTheme.Card.cornerRadius)
        .shadow(radius: 2)
    }
}
