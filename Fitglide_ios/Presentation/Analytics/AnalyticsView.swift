//
//  AnalyticsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var isLoading = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab navigation
                tabNavigation
                
                // Content
                TabView(selection: $selectedTab) {
                    trendsView
                        .tag(0)
                    
                    predictionsView
                        .tag(1)
                    
                    insightsView
                        .tag(2)
                    
                    correlationsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Health Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAnalytics) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .task {
                await loadAnalytics()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Analytics")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("AI-powered insights and predictions")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Quick stats
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Trends",
                    value: "\(analyticsService.trends.count)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: theme.primary,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Predictions",
                    value: "\(analyticsService.predictions.count)",
                    icon: "crystal.ball",
                    color: theme.secondary,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Insights",
                    value: "\(analyticsService.insights.count)",
                    icon: "lightbulb.fill",
                    color: theme.tertiary,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.surface)
    }
    
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                TabButton(
                    title: ["Trends", "Predictions", "Insights", "Correlations"][index],
                    index: index,
                    isSelected: selectedTab == index
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(theme.surface)
        .padding(.horizontal)
    }
    
    private var trendsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(analyticsService.trends, id: \.metric) { trend in
                    TrendCard(trend: trend, theme: theme)
                }
            }
            .padding()
        }
    }
    
    private var predictionsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(analyticsService.predictions.enumerated()), id: \.offset) { index, prediction in
                    PredictionCard(prediction: prediction, theme: theme)
                }
            }
            .padding()
        }
    }
    
    private var insightsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(analyticsService.insights, id: \.title) { insight in
                    InsightCard(insight: insight, theme: theme)
                }
            }
            .padding()
        }
    }
    
    private var correlationsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(analyticsService.correlations, id: \.description) { correlation in
                    CorrelationCard(correlation: correlation, theme: theme)
                }
            }
            .padding()
        }
    }
    
    private func loadAnalytics() async {
        isLoading = true
        defer { isLoading = false }
        
        await analyticsService.analyzeTrends()
        await analyticsService.generatePredictions()
        await analyticsService.generateInsights()
        await analyticsService.analyzeCorrelations()
    }
    
    private func refreshAnalytics() {
        Task {
            await loadAnalytics()
        }
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(FitGlideTheme.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            Text(title)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.surfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TrendCard: View {
    let trend: HealthTrend
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trend.metric)
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text(trend.period)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: trend.trendDirection.icon)
                    .font(.system(size: 24))
                    .foregroundColor(trend.trendDirection.color)
            }
            
            // Stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Current",
                    value: String(format: "%.1f", trend.currentValue),
                    theme: theme
                )
                
                StatItem(
                    title: "Average",
                    value: String(format: "%.1f", trend.averageValue),
                    theme: theme
                )
                
                StatItem(
                    title: "Change",
                    value: String(format: "%.1f%%", trend.changePercentage),
                    color: trend.changePercentage >= 0 ? .green : .red,
                    theme: theme
                )
            }
            
            // Insights
            if !trend.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Insights")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    ForEach(trend.insights, id: \.self) { insight in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundColor(theme.primary)
                            
                            Text(insight)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PredictionCard: View {
    let prediction: HealthPrediction
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.metric)
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text(prediction.timeframe)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "crystal.ball")
                    .font(.system(size: 24))
                    .foregroundColor(theme.secondary)
            }
            
            // Prediction
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("\(prediction.predictedValue)")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Confidence")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.secondary)
                }
            }
            
            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("Based on")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(prediction.reasoning)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: insight.type.icon)
                .font(.system(size: 24))
                .foregroundColor(insight.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(insight.description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var priorityColor: Color {
        switch insight.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct CorrelationCard: View {
    let correlation: HealthCorrelation
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(correlation.factor1) ↔ \(correlation.factor2)")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Impact: \(correlation.impact)")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                    .foregroundColor(theme.tertiary)
            }
            
            // Strength indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Correlation Strength")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("\(Int(abs(correlation.strength) * 100))%")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(correlation.strength >= 0 ? .green : .red)
                }
                
                ProgressView(value: abs(correlation.strength))
                    .progressViewStyle(LinearProgressViewStyle(tint: correlation.strength >= 0 ? .green : .red))
            }
            
            // Description
            Text(correlation.description)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    var color: Color?
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(value)
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(color ?? theme.onSurface)
        }
    }
}

struct TabButton: View {
    let title: String
    let index: Int
    let isSelected: Bool
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(isSelected ? FitGlideTheme.colors(for: .light).primary : FitGlideTheme.colors(for: .light).onSurfaceVariant)
                
                Rectangle()
                    .fill(isSelected ? FitGlideTheme.colors(for: .light).primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 