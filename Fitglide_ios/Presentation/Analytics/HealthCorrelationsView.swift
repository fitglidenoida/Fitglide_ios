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
                VStack(spacing: 24) {
                    // Header
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
                        
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analyzing health correlations...")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            // Correlation Cards
                            VStack(spacing: 16) {
                                ForEach(correlations, id: \.id) { correlation in
                                    CorrelationCard(
                                        title: correlation.title,
                                        description: correlation.description,
                                        strength: correlation.strength,
                                        impact: correlation.impact,
                                        icon: correlation.icon,
                                        color: correlation.color,
                                        theme: theme
                                    )
                                }
                            }
                            
                            // Insights
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Key Insights")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(theme.onSurface)
                                    
                                    Spacer()
                                }
                                
                                ForEach(analyticsService.insights.filter { $0.category == "correlation" }.prefix(3), id: \.id) { insight in
                                    InsightCard(insight: insight, theme: theme)
                                }
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
            await loadCorrelations()
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