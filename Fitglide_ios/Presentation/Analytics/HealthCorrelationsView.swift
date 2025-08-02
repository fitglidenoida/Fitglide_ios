//
//  HealthCorrelationsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct HealthCorrelationsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    @State private var correlations: [HealthCorrelation] = []
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                mainContent
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
            await loadCorrelations()
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            headerSection
            
            if isLoading {
                loadingSection
            } else {
                correlationCardsSection
                insightsSection
            }
        }
        .padding(20)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Correlations")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Discover health connections")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing health correlations...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var correlationCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(correlations.enumerated()), id: \.offset) { index, correlation in
                CorrelationCard(
                    title: "\(correlation.factor1) & \(correlation.factor2)",
                    description: correlation.description,
                    strength: correlation.strength,
                    impact: correlation.impact,
                    icon: getCorrelationIcon(for: correlation.factor1, factor2: correlation.factor2),
                    color: getCorrelationColor(for: correlation.strength),
                    theme: theme
                )
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Key Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            ForEach(analyticsService.insights.filter { $0.type == .recommendation }.prefix(3), id: \.title) { insight in
                InsightCard(
                    title: insight.title,
                    description: insight.description,
                    icon: insight.type.icon,
                    color: insight.type.color,
                    theme: theme
                )
            }
        }
    }
    
    private func loadCorrelations() async {
        isLoading = true
        
        // Load today's data
        await analyticsService.loadTodayData()
        
        // Generate correlations
        await analyticsService.generateCorrelations()
        
        // Get correlations from service
        correlations = analyticsService.correlations
        
        // Generate insights
        await analyticsService.generateInsights()
        
        isLoading = false
    }
    
    private func getCorrelationIcon(for factor1: String, factor2: String) -> String {
        if factor1.lowercased().contains("sleep") || factor2.lowercased().contains("sleep") {
            return "bed.double.fill"
        } else if factor1.lowercased().contains("activity") || factor2.lowercased().contains("activity") {
            return "figure.run"
        } else if factor1.lowercased().contains("nutrition") || factor2.lowercased().contains("nutrition") {
            return "fork.knife"
        } else if factor1.lowercased().contains("stress") || factor2.lowercased().contains("stress") {
            return "heart.fill"
        } else {
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func getCorrelationColor(for strength: Double) -> Color {
        let absStrength = abs(strength)
        if absStrength >= 0.7 {
            return strength > 0 ? .green : .red
        } else if absStrength >= 0.4 {
            return strength > 0 ? .blue : .orange
        } else {
            return .gray
        }
    }
}

struct CorrelationCard: View {
    let title: String
    let description: String
    let strength: Double
    let impact: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    private var strengthText: String {
        String(format: "%.2f", abs(strength))
    }
    
    private var isPositive: Bool {
        strength > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
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
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Correlation Strength")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(strengthText)
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(isPositive ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Impact")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(impact)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(isPositive ? .green : .red)
                }
            }
            
            // Correlation strength indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.surfaceVariant)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPositive ? Color.green : Color.red)
                        .frame(width: geometry.size.width * abs(strength), height: 8)
                        .animation(.easeInOut(duration: 1.0), value: strength)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
} 