//
//  FitnessTrendsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct FitnessTrendsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
                                Text("Fitness Trends")
                                    .font(FitGlideTheme.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Track your progress over time")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
                        }
                        
                        // Quick Stats
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            TrendStatCard(
                                title: "Weekly Steps",
                                value: "45,230",
                                change: "+12%",
                                isPositive: true,
                                theme: theme
                            )
                            
                            TrendStatCard(
                                title: "Calories Burned",
                                value: "2,450",
                                change: "+8%",
                                isPositive: true,
                                theme: theme
                            )
                            
                            TrendStatCard(
                                title: "Workouts",
                                value: "5",
                                change: "+2",
                                isPositive: true,
                                theme: theme
                            )
                        }
                    }
                    
                    // Progress Charts
                    VStack(spacing: 20) {
                        // Steps Progress
                        TrendChartCard(
                            title: "Steps Progress",
                            subtitle: "Last 7 days",
                            data: [8000, 9500, 7200, 11000, 8900, 10200, 9800],
                            labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                            color: .green,
                            theme: theme
                        )
                        
                        // Calories Progress
                        TrendChartCard(
                            title: "Calories Burned",
                            subtitle: "Last 7 days",
                            data: [320, 380, 290, 450, 360, 420, 390],
                            labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                            color: .orange,
                            theme: theme
                        )
                    }
                    
                    // Insights
                    VStack(spacing: 16) {
                        HStack {
                            Text("Insights")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            InsightRow(
                                title: "Consistent Progress",
                                description: "Your step count has increased by 15% this week",
                                icon: "arrow.up.circle.fill",
                                color: .green,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Goal Achievement",
                                description: "You've met your daily step goal 5 out of 7 days",
                                icon: "target",
                                color: .blue,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Workout Consistency",
                                description: "Great job maintaining regular workout sessions",
                                icon: "figure.run",
                                color: .purple,
                                theme: theme
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

struct TrendStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(value)
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                
                Text(change)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct TrendChartCard: View {
    let title: String
    let subtitle: String
    let data: [Double]
    let labels: [String]
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 30, height: CGFloat(value / 12000 * 100))
                            .animation(.easeInOut(duration: 0.5), value: value)
                        
                        Text(labels[index])
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct InsightRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
} 