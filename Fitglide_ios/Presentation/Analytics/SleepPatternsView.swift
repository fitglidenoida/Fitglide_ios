//
//  SleepPatternsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct SleepPatternsView: View {
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
                                Text("Sleep Patterns")
                                    .font(FitGlideTheme.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Monitor your sleep quality")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
                        }
                        
                        // Sleep Stats
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            SleepStatCard(
                                title: "Avg Sleep",
                                value: "7.5h",
                                target: "8h",
                                percentage: 0.94,
                                theme: theme
                            )
                            
                            SleepStatCard(
                                title: "Deep Sleep",
                                value: "1.2h",
                                target: "2h",
                                percentage: 0.60,
                                theme: theme
                            )
                            
                            SleepStatCard(
                                title: "Sleep Debt",
                                value: "2.5h",
                                target: "0h",
                                percentage: 0.0,
                                theme: theme
                            )
                        }
                    }
                    
                    // Sleep Quality Chart
                    SleepQualityChart(theme: theme)
                    
                    // Sleep Schedule
                    SleepScheduleCard(theme: theme)
                    
                    // Insights
                    VStack(spacing: 16) {
                        HStack {
                            Text("Sleep Insights")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            InsightRow(
                                title: "Good Sleep Duration",
                                description: "You're getting close to your 8-hour sleep goal consistently.",
                                icon: "moon.stars.fill",
                                color: .green,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Deep Sleep Opportunity",
                                description: "Your deep sleep is below target. Try reducing screen time before bed.",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Sleep Debt Building",
                                description: "You've accumulated 2.5 hours of sleep debt this week.",
                                icon: "bed.double.fill",
                                color: .red,
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

struct SleepStatCard: View {
    let title: String
    let value: String
    let target: String
    let percentage: Double
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
            
            Text("Target: \(target)")
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.surfaceVariant)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(percentage >= 0.8 ? Color.green : percentage >= 0.6 ? Color.orange : Color.red)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .animation(.easeInOut(duration: 1.0), value: percentage)
                }
            }
            .frame(height: 4)
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

struct SleepQualityChart: View {
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Quality Trend")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("Last 7 days")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            // Simple sleep quality chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(sleepData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 8) {
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(data.quality >= 0.8 ? Color.green : data.quality >= 0.6 ? Color.orange : Color.red)
                                .frame(width: 30, height: CGFloat(data.quality * 80))
                                .animation(.easeInOut(duration: 0.5), value: data.quality)
                            
                            Text("\(Int(data.hours))h")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        Text(data.day)
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
    
    private var sleepData: [(day: String, hours: Double, quality: Double)] {
        [
            ("Mon", 7.5, 0.85),
            ("Tue", 8.2, 0.90),
            ("Wed", 6.8, 0.70),
            ("Thu", 7.9, 0.88),
            ("Fri", 8.5, 0.92),
            ("Sat", 9.1, 0.95),
            ("Sun", 7.2, 0.75)
        ]
    }
}

struct SleepScheduleCard: View {
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Schedule")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("Your typical sleep pattern")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            VStack(spacing: 12) {
                SleepTimeRow(
                    label: "Bedtime",
                    time: "10:30 PM",
                    icon: "bed.double.fill",
                    color: .purple,
                    theme: theme
                )
                
                SleepTimeRow(
                    label: "Wake Time",
                    time: "6:30 AM",
                    icon: "sun.max.fill",
                    color: .orange,
                    theme: theme
                )
                
                SleepTimeRow(
                    label: "Sleep Duration",
                    time: "8 hours",
                    icon: "clock.fill",
                    color: .blue,
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct SleepTimeRow: View {
    let label: String
    let time: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
            
            Spacer()
            
            Text(time)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
        }
    }
} 