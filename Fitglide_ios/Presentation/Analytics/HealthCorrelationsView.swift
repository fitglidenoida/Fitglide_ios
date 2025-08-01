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
                    }
                    
                    // Correlation Cards
                    VStack(spacing: 16) {
                        CorrelationCard(
                            title: "Sleep & Activity",
                            description: "Better sleep leads to higher activity levels",
                            strength: 0.85,
                            impact: "Strong Positive",
                            icon: "bed.double.fill",
                            color: .blue,
                            theme: theme
                        )
                        
                        CorrelationCard(
                            title: "Nutrition & Energy",
                            description: "Balanced nutrition improves energy levels",
                            strength: 0.72,
                            impact: "Moderate Positive",
                            icon: "fork.knife",
                            color: .green,
                            theme: theme
                        )
                        
                        CorrelationCard(
                            title: "Stress & Recovery",
                            description: "High stress reduces recovery quality",
                            strength: -0.68,
                            impact: "Moderate Negative",
                            icon: "heart.fill",
                            color: .red,
                            theme: theme
                        )
                        
                        CorrelationCard(
                            title: "Exercise & Sleep",
                            description: "Regular exercise improves sleep quality",
                            strength: 0.78,
                            impact: "Strong Positive",
                            icon: "figure.run",
                            color: .purple,
                            theme: theme
                        )
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
                        
                        VStack(spacing: 12) {
                            InsightRow(
                                title: "Sleep is Key",
                                description: "Your sleep quality has the strongest correlation with overall health metrics.",
                                icon: "star.fill",
                                color: .yellow,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Exercise Benefits",
                                description: "Regular exercise shows strong positive correlations with multiple health factors.",
                                icon: "arrow.up.circle.fill",
                                color: .green,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Stress Management",
                                description: "Managing stress levels could significantly improve your recovery and sleep quality.",
                                icon: "brain.head.profile",
                                color: .blue,
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