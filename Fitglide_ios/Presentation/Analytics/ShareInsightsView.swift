//
//  ShareInsightsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct ShareInsightsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedInsight = 0
    @State private var isSharing = false
    @State private var insights: [String] = []
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share Insights")
                                    .font(FitGlideTheme.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Share your health achievements")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if insights.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Generating insights...")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Insight Selection
                        VStack(spacing: 16) {
                            HStack {
                                Text("Choose Insight to Share")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.onSurface)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                                    InsightShareCard(
                                        text: insight,
                                        isSelected: selectedInsight == index,
                                        onTap: { selectedInsight = index },
                                        theme: theme
                                    )
                                }
                            }
                        }
                        
                        // Preview
                        VStack(spacing: 16) {
                            HStack {
                                Text("Preview")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.onSurface)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                SharePreviewCard(
                                    text: insights[selectedInsight],
                                    theme: theme
                                )
                            }
                        }
                        
                        // Share Options
                        VStack(spacing: 16) {
                            HStack {
                                Text("Share Options")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.onSurface)
                                
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ShareOptionCard(
                                    title: "Social Media",
                                    icon: "square.and.arrow.up",
                                    color: .blue,
                                    onTap: { shareToSocialMedia() },
                                    theme: theme
                                )
                                
                                ShareOptionCard(
                                    title: "Friends",
                                    icon: "person.2.fill",
                                    color: .green,
                                    onTap: { shareToFriends() },
                                    theme: theme
                                )
                                
                                ShareOptionCard(
                                    title: "Export",
                                    icon: "square.and.arrow.down",
                                    color: .orange,
                                    onTap: { exportInsight() },
                                    theme: theme
                                )
                                
                                ShareOptionCard(
                                    title: "Copy Link",
                                    icon: "link",
                                    color: .purple,
                                    onTap: { copyLink() },
                                    theme: theme
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .task {
            await generateInsights()
        }
    }
    
    private func generateInsights() async {
        // Load today's data
        await analyticsService.loadTodayData()
        
        // Generate insights based on real data
        insights = [
            "Weekly Progress: Achieved \(analyticsService.todaySteps) steps this week! 🚶‍♂️",
            "Sleep Quality: Maintained \(analyticsService.lastNightSleep) average sleep with great quality 🌙",
            "Fitness Goal: Burned \(analyticsService.todayCalories) calories today! 💪",
            "Nutrition Balance: Staying on track with your health goals 🍎"
        ]
    }
    
    private func shareToSocialMedia() {
        isSharing = true
        // Implement social media sharing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSharing = false
        }
    }
    
    private func shareToFriends() {
        isSharing = true
        // Implement friend sharing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSharing = false
        }
    }
    
    private func exportInsight() {
        isSharing = true
        // Implement export
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSharing = false
        }
    }
    
    private func copyLink() {
        // Copy to clipboard
        UIPasteboard.general.string = insights[selectedInsight]
    }
}

struct InsightShareCard: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SharePreviewCard: View {
    let text: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FitGlide")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Just now")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
            }
            
            Text(text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: "heart")
                    .font(.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text("0")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ShareOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 