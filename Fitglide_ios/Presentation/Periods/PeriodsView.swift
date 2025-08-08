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
                
                ProgressView(value: min(max(viewModel.cycleProgress, 0), 1))
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
                CalendarView(viewModel: viewModel, theme: theme, onAddPeriod: { showAddPeriod = true })
                
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
            
            if viewModel.periods.isEmpty {
                Text("Add period data to see fertility predictions")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            } else {
                let fertilityPrediction = viewModel.predictFertilityWindow()
                
                if viewModel.isInFertilityWindow {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.quaternary)
                            Text("You're in your fertile window")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.quaternary)
                                .fontWeight(.medium)
                        }
                        
                        Text("This is the best time for conception. Your fertility window typically lasts 6 days.")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        if fertilityPrediction.confidence < 0.7 {
                            Text("Prediction confidence: \(String(format: "%.0f", fertilityPrediction.confidence * 100))%")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next fertile window: \(fertilityPrediction.fertileStart, style: .date)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        let daysUntilFertile = Calendar.current.dateComponents([.day], from: Date(), to: fertilityPrediction.fertileStart).day ?? 0
                        if daysUntilFertile > 0 {
                            Text("\(daysUntilFertile) days until fertile window")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        if fertilityPrediction.confidence < 0.7 {
                            Text("Prediction confidence: \(String(format: "%.0f", fertilityPrediction.confidence * 100))%")
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
    }
    
    private var recentPeriodsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Periods")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if viewModel.periods.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("No periods recorded yet")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("Add your first period to start tracking your cycle")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentPeriods, id: \.id) { period in
                    HStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(period.startDate, style: .date)
                                .font(FitGlideTheme.bodyMedium)
                            
                            Text("\(period.duration) days • \(period.flow.rawValue) flow")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        Spacer()
                        
                        // Show if this is the current period
                        if Calendar.current.isDate(period.startDate, inSameDayAs: viewModel.lastPeriodStart) {
                            Text("Current")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.primary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Show cycle statistics
                if viewModel.periods.count >= 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Average Cycle")
                                    .font(FitGlideTheme.caption)
                                    .foregroundColor(theme.onSurfaceVariant)
                                Text("\(viewModel.averageCycleLength) days")
                                    .font(FitGlideTheme.bodyMedium)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Average Period")
                                    .font(FitGlideTheme.caption)
                                    .foregroundColor(theme.onSurfaceVariant)
                                Text("\(viewModel.averagePeriodLength) days")
                                    .font(FitGlideTheme.bodyMedium)
                                    .fontWeight(.medium)
                            }
                        }
                    }
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
                if viewModel.periods.isEmpty {
                    // Empty state for insights
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Text("No Insights Yet")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(theme.onSurface)
                        
                        Text("Add your first period to unlock personalized cycle insights and health correlations")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showAddPeriod = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Period")
                            }
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(.white)
                            .padding()
                            .background(theme.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 40)
                } else {
                    // Cycle insights
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(theme.primary)
                            Text("Cycle Insights")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if viewModel.cycleInsights.isEmpty {
                            Text("Add more period data to generate insights")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(viewModel.cycleInsights, id: \.self) { insight in
                                PeriodInsightCard(insight: insight, theme: theme)
                            }
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Health correlations
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.text.square")
                                .foregroundColor(theme.quaternary)
                            Text("Health Correlations")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        if viewModel.healthCorrelations.isEmpty {
                            Text("Track symptoms to discover health correlations")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurfaceVariant)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(viewModel.healthCorrelations, id: \.self) { correlation in
                                PeriodCorrelationCard(correlation: correlation, theme: theme)
                            }
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.periods.isEmpty {
                    // Empty state for settings
                    VStack(spacing: 20) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 48))
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Text("Settings")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(theme.onSurface)
                        
                        Text("Add your first period to see cycle statistics and customize your tracking preferences")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showAddPeriod = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Period")
                            }
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(.white)
                            .padding()
                            .background(theme.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 40)
                } else {
                    // Cycle settings
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundColor(theme.primary)
                            Text("Cycle Statistics")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Average Cycle Length")
                                    .font(FitGlideTheme.bodyMedium)
                                Spacer()
                                Text("\(viewModel.averageCycleLength) days")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            HStack {
                                Text("Average Period Length")
                                    .font(FitGlideTheme.bodyMedium)
                                Spacer()
                                Text("\(viewModel.averagePeriodLength) days")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            HStack {
                                Text("Last Period Start")
                                    .font(FitGlideTheme.bodyMedium)
                                Spacer()
                                Text(viewModel.lastPeriodStart, style: .date)
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            HStack {
                                Text("Current Cycle Day")
                                    .font(FitGlideTheme.bodyMedium)
                                Spacer()
                                Text("Day \(viewModel.currentCycleDay)")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.primary)
                                    .fontWeight(.medium)
                            }
                            
                            if viewModel.periods.count >= 2 {
                                HStack {
                                    Text("Total Periods Recorded")
                                        .font(FitGlideTheme.bodyMedium)
                                    Spacer()
                                    Text("\(viewModel.periods.count)")
                                        .font(FitGlideTheme.bodyMedium)
                                        .foregroundColor(theme.onSurfaceVariant)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Notifications
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(theme.quaternary)
                            Text("Notifications")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Toggle("Period Reminders", isOn: $viewModel.periodReminders)
                                .font(FitGlideTheme.bodyMedium)
                            
                            Toggle("Fertility Window Alerts", isOn: $viewModel.fertilityAlerts)
                                .font(FitGlideTheme.bodyMedium)
                            
                            Toggle("Symptom Tracking Reminders", isOn: $viewModel.symptomReminders)
                                .font(FitGlideTheme.bodyMedium)
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Data Management
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(theme.onSurfaceVariant)
                            Text("Data Management")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                // TODO: Export data functionality
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Period Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurface)
                            }
                            
                            Button(action: {
                                // TODO: Import data functionality
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import Period Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurface)
                            }
                            
                            Button(action: {
                                // TODO: Clear data functionality
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Data")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
    let onAddPeriod: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cycle Calendar")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Current cycle day indicator
                if viewModel.currentCycleDay > 0 {
                    Text("Day \(viewModel.currentCycleDay)")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if viewModel.periods.isEmpty {
                // Empty state when no period data - make it clickable
                Button(action: onAddPeriod) {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(theme.primary)
                        
                        Text("No period data yet")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                        
                        Text("Tap to add your first period")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Calendar grid with real data
                VStack(spacing: 8) {
                    // Day labels
                    HStack(spacing: 8) {
                        ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                            Text(day)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(0..<35, id: \.self) { day in
                            Button(action: {
                                // TODO: Add period starting on selected date
                                onAddPeriod()
                            }) {
                                CalendarDayView(
                                    day: day + 1,
                                    isPeriodDay: viewModel.isPeriodDay(day: day + 1),
                                    isFertileDay: viewModel.isFertileDay(day: day + 1),
                                    isCurrentDay: isCurrentDay(day: day + 1),
                                    theme: theme
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 12, height: 12)
                        Text("Period")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.quaternary.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text("Fertile")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .stroke(theme.primary, lineWidth: 2)
                            .frame(width: 12, height: 12)
                        Text("Today")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func isCurrentDay(day: Int) -> Bool {
        // Check if this calendar day represents today
        guard let lastPeriod = viewModel.periods.last else { return false }
        
        let today = Date()
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: today).day ?? 0
        let currentCycleDay = daysSinceLastPeriod + 1
        
        let cycleStartDay = max(1, currentCycleDay - 17)
        let calendarDay = day + cycleStartDay - 1
        
        return calendarDay == currentCycleDay
    }
    
    private func calculateDateForCalendarDay(day: Int) -> Date {
        // Calculate the actual date for a given calendar day position
        guard let lastPeriod = viewModel.periods.last else { return Date() }
        
        let today = Date()
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate, to: today).day ?? 0
        let currentCycleDay = daysSinceLastPeriod + 1
        
        let cycleStartDay = max(1, currentCycleDay - 17)
        let calendarDay = day + cycleStartDay - 1
        
        // Calculate the date for this calendar day
        let daysFromLastPeriod = calendarDay - currentCycleDay
        return Calendar.current.date(byAdding: .day, value: daysFromLastPeriod, to: today) ?? today
    }
}

struct CalendarDayView: View {
    let day: Int
    let isPeriodDay: Bool
    let isFertileDay: Bool
    let isCurrentDay: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
            
            if isCurrentDay && !isPeriodDay {
                Circle()
                    .stroke(theme.primary, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }
            
            Text("\(day)")
                .font(FitGlideTheme.caption)
                .foregroundColor(textColor)
                .fontWeight(isCurrentDay ? .bold : .regular)
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
        } else if isFertileDay {
            return theme.onSurfaceVariant
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