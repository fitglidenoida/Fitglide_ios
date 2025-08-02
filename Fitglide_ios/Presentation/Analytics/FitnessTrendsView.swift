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
    @State private var isLoading = true
    @State private var weeklyStepsData: [Double] = []
    @State private var weeklyCaloriesData: [Double] = []
    @State private var weeklyWorkoutsData: [Double] = []
    @State private var weekLabels: [String] = []
    
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
                                value: analyticsService.todaySteps,
                                change: calculateWeeklyChange(steps: weeklyStepsData),
                                isPositive: calculateWeeklyChange(steps: weeklyStepsData).hasPrefix("+"),
                                theme: theme
                            )
                            
                            TrendStatCard(
                                title: "Calories Burned",
                                value: analyticsService.todayCalories,
                                change: calculateWeeklyChange(calories: weeklyCaloriesData),
                                isPositive: calculateWeeklyChange(calories: weeklyCaloriesData).hasPrefix("+"),
                                theme: theme
                            )
                            
                            TrendStatCard(
                                title: "Workouts",
                                value: String(weeklyWorkoutsData.last ?? 0),
                                change: calculateWeeklyChange(workouts: weeklyWorkoutsData),
                                isPositive: calculateWeeklyChange(workouts: weeklyWorkoutsData).hasPrefix("+"),
                                theme: theme
                            )
                        }
                    }
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading fitness trends...")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Progress Charts
                        VStack(spacing: 20) {
                            // Steps Progress
                            if !weeklyStepsData.isEmpty {
                                TrendChartCard(
                                    title: "Steps Progress",
                                    subtitle: "Last 7 days",
                                    data: weeklyStepsData,
                                    labels: weekLabels,
                                    color: .green,
                                    theme: theme
                                )
                            }
                            
                            // Calories Progress
                            if !weeklyCaloriesData.isEmpty {
                                TrendChartCard(
                                    title: "Calories Burned",
                                    subtitle: "Last 7 days",
                                    data: weeklyCaloriesData,
                                    labels: weekLabels,
                                    color: .orange,
                                    theme: theme
                                )
                            }
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
                            
                            ForEach(Array(analyticsService.insights.prefix(3).enumerated()), id: \.offset) { index, insight in
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
            await loadFitnessTrends()
        }
    }
    
    private func loadFitnessTrends() async {
        isLoading = true
        
        // Load today's data from Strapi
        await loadTodayDataFromStrapi()
        
        // Load weekly trends
        await analyticsService.analyzeTrends(days: 7)
        
        // Generate insights
        await analyticsService.generateInsights()
        
        // Prepare chart data
        await prepareChartData()
        
        isLoading = false
    }
    
    private func loadTodayDataFromStrapi() async {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        do {
            let healthLogs = try await analyticsService.getWeeklyHealthData(from: startOfDay, to: endOfDay)
            
            if let todayLog = healthLogs.first {
                analyticsService.todaySteps = String(todayLog.steps ?? 0)
                analyticsService.todayCalories = String(format: "%.0f", todayLog.caloriesBurned ?? 0)
            } else {
                analyticsService.todaySteps = "0"
                analyticsService.todayCalories = "0"
            }
        } catch {
            print("FitnessTrendsView: Failed to load today's data from Strapi: \(error)")
            analyticsService.todaySteps = "0"
            analyticsService.todayCalories = "0"
        }
    }
    
    private func prepareChartData() async {
        // Get last 7 days data from Strapi
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        
        weekLabels = []
        weeklyStepsData = []
        weeklyCaloriesData = []
        weeklyWorkoutsData = []
        
        do {
            // Fetch weekly data from Strapi
            let weeklySteps = try await analyticsService.getWeeklyStepsData(from: startDate, to: today)
            let weeklyCalories = try await analyticsService.getWeeklyCaloriesData(from: startDate, to: today)
            
            // Generate day labels
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                let dayLabel = formatDayLabel(date)
                weekLabels.insert(dayLabel, at: 0)
            }
            
            // Use Strapi data or 0 if no data
            weeklyStepsData = weeklySteps.map { Double($0) }
            weeklyCaloriesData = weeklyCalories.map { Double($0) }
            
            // Placeholder for workout data (will be implemented later)
            weeklyWorkoutsData = Array(repeating: 0.0, count: 7)
            
        } catch {
            print("FitnessTrendsView: Failed to fetch weekly data from Strapi: \(error)")
            
            // Fallback to 0 values
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                let dayLabel = formatDayLabel(date)
                weekLabels.insert(dayLabel, at: 0)
                
                weeklyStepsData.insert(0, at: 0)
                weeklyCaloriesData.insert(0, at: 0)
                weeklyWorkoutsData.insert(0, at: 0)
            }
        }
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func calculateWeeklyChange(steps: [Double] = [], calories: [Double] = [], workouts: [Double] = []) -> String {
        let data = !steps.isEmpty ? steps : (!calories.isEmpty ? calories : workouts)
        guard data.count >= 2 else { return "0%" }
        
        let current = data.last ?? 0
        let previous = data[data.count - 2]
        
        if previous == 0 {
            return current > 0 ? "+100%" : "0%"
        }
        
        let change = ((current - previous) / previous) * 100
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.0f%%", sign, change)
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