//
//  AnalyticsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct AnalyticsView: View {
    @StateObject private var analyticsService: AnalyticsService
    @State private var selectedTab = 0
    @State private var animateContent = false
    @State private var isLoading = false
    
    @Environment(\.colorScheme) var colorScheme
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        _analyticsService = StateObject(wrappedValue: AnalyticsService(
            healthService: healthService,
            strapiRepository: strapiRepository,
            authRepository: authRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    modernHeaderSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Analytics Categories
                    analyticsCategoriesSection
                    
                    // Wellness Insights
                    wellnessInsightsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(theme.background)
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            Task {
                await loadAnalytics()
            }
        }
    }
    
    // MARK: - Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Analytics")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Track your wellness journey")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(action: {
                    // Refresh analytics
                    Task {
                        await refreshAnalytics()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(theme.primary.opacity(0.1))
                        )
                }
            }
            
            // Indian Health Quote
            VStack(spacing: 8) {
                Text("""
                    "Health is wealth - your body is your greatest asset."
                    """)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.center)
                
                Text("Ancient Indian Wisdom")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Stats")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStatCard(
                    title: "Steps",
                    value: "8,247",
                    icon: "figure.walk",
                    color: .green,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: "342",
                    icon: "flame.fill",
                    color: .orange,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Sleep",
                    value: "7.5h",
                    icon: "moon.fill",
                    color: .purple,
                    theme: theme
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Analytics Categories Section
    private var analyticsCategoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analytics Categories")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                AnalyticsCategoryCard(
                    title: "Fitness Trends",
                    description: "Track your progress over time",
                    icon: "figure.run",
                    color: .green,
                    theme: theme
                )
                
                AnalyticsCategoryCard(
                    title: "Nutrition Analysis",
                    description: "Understand your eating patterns",
                    icon: "fork.knife",
                    color: .orange,
                    theme: theme
                )
                
                AnalyticsCategoryCard(
                    title: "Sleep Patterns",
                    description: "Monitor your sleep quality",
                    icon: "moon.fill",
                    color: .purple,
                    theme: theme
                )
                
                AnalyticsCategoryCard(
                    title: "Health Correlations",
                    description: "Discover health connections",
                    icon: "chart.xyaxis.line",
                    color: .blue,
                    theme: theme
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Wellness Insights Section
    private var wellnessInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Wellness Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    title: "Great Progress!",
                    description: "Your step count has increased by 15% this week",
                    icon: "arrow.up.circle.fill",
                    color: .green,
                    theme: theme
                )
                
                InsightCard(
                    title: "Sleep Improvement",
                    description: "Your sleep quality has improved by 20%",
                    icon: "bed.double.fill",
                    color: .blue,
                    theme: theme
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: theme.primary,
                    action: { /* Export report */ },
                    theme: theme
                )
                
                QuickActionButton(
                    title: "Share Insights",
                    icon: "share",
                    color: .blue,
                    action: { /* Share insights */ },
                    theme: theme
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
    
    // MARK: - Helper Functions
    private func loadAnalytics() async {
        isLoading = true
        await analyticsService.analyzeTrends()
        await analyticsService.generatePredictions()
        await analyticsService.generateInsights()
        await analyticsService.analyzeCorrelations()
        isLoading = false
    }
    
    private func refreshAnalytics() async {
        isLoading = true
        await analyticsService.analyzeTrends()
        await analyticsService.generatePredictions()
        await analyticsService.generateInsights()
        await analyticsService.analyzeCorrelations()
        isLoading = false
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(FitGlideTheme.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct AnalyticsCategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.titleMedium)
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
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
    }
}


