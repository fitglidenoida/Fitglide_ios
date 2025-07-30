//
//  PeriodsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI
import HealthKit

struct PeriodsView: View {
    @ObservedObject var viewModel: PeriodsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showAddPeriod = false
    @State private var showAddSymptom = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with cycle info
                cycleHeader
                
                // Tab navigation
                tabNavigation
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    cycleCalendarView
                        .tag(0)
                    
                    symptomsView
                        .tag(1)
                    
                    insightsView
                        .tag(2)
                    
                    settingsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Cycle Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddPeriod = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddPeriod) {
                AddPeriodView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddSymptom) {
                AddSymptomView(viewModel: viewModel)
            }
        }
    }
    
    private var cycleHeader: some View {
        VStack(spacing: 16) {
            // Current cycle status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Cycle")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("Day \(viewModel.currentCycleDay)")
                        .font(FitGlideTheme.titleLarge)
                        .foregroundColor(theme.onSurface)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Period")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(viewModel.nextPeriodDate, style: .date)
                        .font(FitGlideTheme.titleMedium)
                        .foregroundColor(theme.primary)
                }
            }
            
            // Cycle progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cycle Progress")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("\(viewModel.cycleProgressPercentage, specifier: "%.0f")%")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.primary)
                }
                
                ProgressView(value: viewModel.cycleProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                PeriodTabButton(
                    title: ["Calendar", "Symptoms", "Insights", "Settings"][index],
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
    
    private var cycleCalendarView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Calendar view
                CalendarView(viewModel: viewModel, theme: theme)
                
                // Fertility window
                fertilityWindowCard
                
                // Recent periods
                recentPeriodsCard
            }
            .padding()
        }
    }
    
    private var fertilityWindowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(theme.quaternary)
                Text("Fertility Window")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if viewModel.isInFertilityWindow {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.quaternary)
                    Text("You're in your fertile window")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.quaternary)
                }
            } else {
                Text("Next fertile window: \(viewModel.nextFertilityWindow, style: .date)")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var recentPeriodsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Periods")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ForEach(viewModel.recentPeriods, id: \.id) { period in
                HStack {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 8, height: 8)
                    
                    Text(period.startDate, style: .date)
                        .font(FitGlideTheme.bodyMedium)
                    
                    Spacer()
                    
                    Text("\(period.duration) days")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var symptomsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add symptom button
                Button(action: { showAddSymptom = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Symptom")
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Today's symptoms
                if !viewModel.todaySymptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Symptoms")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        ForEach(viewModel.todaySymptoms, id: \.id) { symptom in
                            SymptomCard(symptom: symptom, theme: theme)
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Symptom history
                VStack(alignment: .leading, spacing: 12) {
                    Text("Symptom History")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                    
                    ForEach(viewModel.symptomHistory, id: \.id) { entry in
                        SymptomHistoryCard(entry: entry, theme: theme)
                    }
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private var insightsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cycle insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cycle Insights")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                    
                    ForEach(viewModel.cycleInsights, id: \.self) { insight in
                        PeriodInsightCard(insight: insight, theme: theme)
                    }
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Health correlations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Correlations")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                    
                    ForEach(viewModel.healthCorrelations, id: \.self) { correlation in
                        PeriodCorrelationCard(correlation: correlation, theme: theme)
                    }
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cycle settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cycle Settings")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Average Cycle Length")
                            Spacer()
                            Text("\(viewModel.averageCycleLength) days")
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        HStack {
                            Text("Average Period Length")
                            Spacer()
                            Text("\(viewModel.averagePeriodLength) days")
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        HStack {
                            Text("Last Period Start")
                            Spacer()
                            Text(viewModel.lastPeriodStart, style: .date)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Notifications
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        Toggle("Period Reminders", isOn: $viewModel.periodReminders)
                        Toggle("Fertility Window Alerts", isOn: $viewModel.fertilityAlerts)
                        Toggle("Symptom Tracking Reminders", isOn: $viewModel.symptomReminders)
                    }
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct PeriodTabButton: View {
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

struct CalendarView: View {
    @ObservedObject var viewModel: PeriodsViewModel
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle Calendar")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
            
            // Simple calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<35, id: \.self) { day in
                    CalendarDayView(
                        day: day + 1,
                        isPeriodDay: viewModel.isPeriodDay(day: day + 1),
                        isFertileDay: viewModel.isFertileDay(day: day + 1),
                        theme: theme
                    )
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CalendarDayView: View {
    let day: Int
    let isPeriodDay: Bool
    let isFertileDay: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
            
            Text("\(day)")
                .font(FitGlideTheme.caption)
                .foregroundColor(textColor)
        }
    }
    
    private var backgroundColor: Color {
        if isPeriodDay {
            return theme.primary
        } else if isFertileDay {
            return theme.quaternary.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isPeriodDay {
            return theme.onPrimary
        } else {
            return theme.onSurface
        }
    }
}

struct SymptomCard: View {
    let symptom: SymptomEntry
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Image(systemName: symptom.icon)
                .foregroundColor(theme.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(symptom.name)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                
                Text(symptom.severity.rawValue)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(symptom.date, style: .time)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.vertical, 8)
    }
}

struct SymptomHistoryCard: View {
    let entry: SymptomHistoryEntry
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(entry.symptoms.count) symptoms")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            HStack {
                ForEach(entry.symptoms, id: \.self) { symptom in
                    Text(symptom)
                        .font(FitGlideTheme.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primary.opacity(0.1))
                        .foregroundColor(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(theme.surfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PeriodInsightCard: View {
    let insight: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(theme.secondary)
            
            Text(insight)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
            
            Spacer()
        }
        .padding()
        .background(theme.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PeriodCorrelationCard: View {
    let correlation: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(theme.tertiary)
            
            Text(correlation)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
            
            Spacer()
        }
        .padding()
        .background(theme.tertiary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
} 