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
    @State private var isLoading = true
    @State private var sleepData = SleepAnalysisData()
    @State private var selectedDataPoint: Int? = nil
    @State private var weeklySleepData: [AnalyticsSleepData] = []
    
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
            await loadSleepData()
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            headerSection
            
            if isLoading {
                loadingSection
            } else {
                sleepStatsSection
                sleepQualityChartSection
                sleepScheduleSection
                insightsSection
            }
        }
        .padding(20)
    }
    
    private var headerSection: some View {
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
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading sleep data...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var sleepStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SleepStatCard(
                title: "Avg Sleep",
                value: String(format: "%.1fh", sleepData.averageSleepHours),
                target: "8h",
                percentage: sleepData.averageSleepPercentage,
                theme: theme
            )
            
            SleepStatCard(
                title: "Deep Sleep",
                value: String(format: "%.1fh", sleepData.averageDeepSleepHours),
                target: "2h",
                percentage: sleepData.deepSleepPercentage,
                theme: theme
            )
            
            SleepStatCard(
                title: "Sleep Debt",
                value: String(format: "%.1fh", sleepData.sleepDebtHours),
                target: "0h",
                percentage: 0.0,
                theme: theme
            )
        }
    }
    
    private var sleepQualityChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Quality Trend")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            SleepQualityChart(
                theme: theme,
                sleepScores: sleepData.weeklySleepScores,
                weeklySleepData: weeklySleepData,
                selectedDataPoint: $selectedDataPoint
            )
            .frame(height: 200)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.surface)
        .cornerRadius(16)
        .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var sleepScheduleSection: some View {
        SleepPatternScheduleCard(
            theme: theme,
            bedTime: sleepData.averageBedTime,
            wakeTime: sleepData.averageWakeTime
        )
    }
    
    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if analyticsService.sleepInsights.isEmpty {
                Text("No sleep insights available yet. Complete more sleep tracking to get personalized recommendations.")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ForEach(Array(analyticsService.sleepInsights.enumerated()), id: \.offset) { index, insight in
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
    
    private func loadSleepData() async {
        isLoading = true
        
        // Load today's data
        await analyticsService.loadTodayData()
        
        // Generate sleep insights specifically
        await analyticsService.generateSleepInsights()
        
        // Calculate sleep analysis data
        await calculateSleepData()
        
        isLoading = false
    }
    
    private func calculateSleepData() async {
        print("SleepPatternsView: Starting calculateSleepData...")
        
        // Get last 7 days of sleep data from Strapi
        do {
            let weeklySleepData = try await analyticsService.getWeeklySleepData()
            self.weeklySleepData = weeklySleepData
            print("SleepPatternsView: Got \(weeklySleepData.count) days of sleep data from Strapi")
            
            var totalSleepHours: Double = 0
            var totalDeepSleepHours: Double = 0
            var sleepScores: [Double] = []
            var daysWithData = 0
            
            for (index, sleepData) in weeklySleepData.enumerated() {
                print("SleepPatternsView: Day \(index): totalSleepHours=\(sleepData.totalSleepHours), deepSleepHours=\(sleepData.deepSleepHours)")
                
                if sleepData.totalSleepHours > 0 {
                    totalSleepHours += sleepData.totalSleepHours
                    totalDeepSleepHours += sleepData.deepSleepHours
                    daysWithData += 1
                    
                    // Calculate sleep score (simplified)
                    let sleepScore = min(100, (sleepData.totalSleepHours / 8.0) * 100)
                    sleepScores.append(sleepScore)
                    print("SleepPatternsView: Day \(index): Added to calculation - sleepScore=\(sleepScore)")
                } else {
                    sleepScores.append(0)
                    print("SleepPatternsView: Day \(index): No data, added 0")
                }
            }
            
            // Calculate averages (only for days with data)
            if daysWithData > 0 {
                sleepData.averageSleepHours = totalSleepHours / Double(daysWithData)
                sleepData.averageDeepSleepHours = totalDeepSleepHours / Double(daysWithData)
            } else {
                sleepData.averageSleepHours = 0
                sleepData.averageDeepSleepHours = 0
            }
            
            sleepData.averageSleepPercentage = sleepData.averageSleepHours / 8.0
            sleepData.deepSleepPercentage = sleepData.averageDeepSleepHours / 2.0
            
            // Calculate sleep debt (simplified)
            sleepData.sleepDebtHours = max(0, 8.0 - sleepData.averageSleepHours)
            
            // Weekly sleep scores
            sleepData.weeklySleepScores = sleepScores
            
            // Average bed/wake times (simplified - could be calculated from actual data)
            sleepData.averageBedTime = "10:30 PM"
            sleepData.averageWakeTime = "6:30 AM"
            
            print("SleepPatternsView: Calculated sleep data - Avg: \(sleepData.averageSleepHours)h, Deep: \(sleepData.averageDeepSleepHours)h, Days with data: \(daysWithData)")
            print("SleepPatternsView: Sleep scores: \(sleepData.weeklySleepScores)")
            
        } catch {
            print("SleepPatternsView: Error loading weekly sleep data: \(error)")
            // Set default values on error
            sleepData.averageSleepHours = 0
            sleepData.averageDeepSleepHours = 0
            sleepData.averageSleepPercentage = 0
            sleepData.deepSleepPercentage = 0
            sleepData.sleepDebtHours = 8.0
            sleepData.weeklySleepScores = Array(repeating: 0, count: 7)
            sleepData.averageBedTime = "N/A"
            sleepData.averageWakeTime = "N/A"
        }
    }
}

// MARK: - Supporting Models
struct SleepAnalysisData {
    var averageSleepHours: Double = 0.0
    var averageDeepSleepHours: Double = 0.0
    var averageSleepPercentage: Double = 0.0
    var deepSleepPercentage: Double = 0.0
    var sleepDebtHours: Double = 0.0
    var weeklySleepScores: [Double] = []
    var averageBedTime: String = ""
    var averageWakeTime: String = ""
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
    let sleepScores: [Double]
    let weeklySleepData: [AnalyticsSleepData]
    @Binding var selectedDataPoint: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Line chart
            GeometryReader { geometry in
                ZStack {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { i in
                            Divider()
                                .background(theme.onSurface.opacity(0.1))
                            if i < 4 {
                                Spacer()
                            }
                        }
                    }
                    
                    // Line chart
                    if sleepScores.count > 1 {
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(sleepScores.count - 1)
                            
                            for (index, score) in sleepScores.enumerated() {
                                let x = CGFloat(index) * stepX
                                let y = height - (CGFloat(score) / 100.0) * height
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(theme.primary, lineWidth: 3)
                        .shadow(color: theme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // Data points
                        ForEach(Array(sleepScores.enumerated()), id: \.offset) { index, score in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(sleepScores.count - 1)
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(score) / 100.0) * height
                            
                            Circle()
                                .fill(selectedDataPoint == index ? theme.primary : theme.primary.opacity(0.7))
                                .frame(width: selectedDataPoint == index ? 12 : 8, height: selectedDataPoint == index ? 12 : 8)
                                .position(x: x, y: y)
                                .shadow(color: theme.primary.opacity(0.5), radius: 2, x: 0, y: 1)
                                .onTapGesture {
                                    if selectedDataPoint == index {
                                        selectedDataPoint = nil
                                    } else {
                                        selectedDataPoint = index
                                    }
                                }
                        }
                        
                        // Tooltip
                        if let selectedIndex = selectedDataPoint, selectedIndex < sleepScores.count {
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let stepX = width / CGFloat(sleepScores.count - 1)
                            let x = CGFloat(selectedIndex) * stepX
                            let y = height - (CGFloat(sleepScores[selectedIndex]) / 100.0) * height
                            
                            let sleepData = weeklySleepData[selectedIndex]
                            let sleepDuration = sleepData.totalSleepHours
                            
                            VStack(spacing: 4) {
                                Text("Sleep Score: \(Int(sleepScores[selectedIndex]))%")
                                    .font(FitGlideTheme.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.onPrimary)
                                
                                Text("Duration: \(Int(sleepDuration))h")
                                    .font(FitGlideTheme.caption)
                                    .foregroundColor(theme.onPrimary.opacity(0.8))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(theme.primary)
                                    .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .position(x: x, y: y - 30)
                        }
                    }
                }
            }
            .frame(height: 120)
            
            // Day labels
            HStack {
                ForEach(Array(sleepScores.enumerated()), id: \.offset) { index, _ in
                    Text(getDayOfWeek(from: index))
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    if index < sleepScores.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func getDayOfWeek(from index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        let dayOfWeek = calendar.date(byAdding: .day, value: -index, to: today)?.formatted(.dateTime.weekday(.abbreviated)) ?? ""
        return dayOfWeek
    }
}

struct SleepPatternScheduleCard: View {
    let theme: FitGlideTheme.Colors
    let bedTime: String
    let wakeTime: String
    
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
                    time: bedTime,
                    icon: "bed.double.fill",
                    color: .purple,
                    theme: theme
                )
                
                SleepTimeRow(
                    label: "Wake Time",
                    time: wakeTime,
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
