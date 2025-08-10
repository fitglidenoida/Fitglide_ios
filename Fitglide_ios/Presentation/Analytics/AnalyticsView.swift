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
    @State private var showFitnessTrends = false
    @State private var showNutritionAnalysis = false
    @State private var showSleepPatterns = false
    @State private var showHealthCorrelations = false
    @State private var showExportReport = false
    @State private var showShareInsights = false
    @State private var showAIPredictions = false
    @State private var navigateToProfile = false
    @State private var showSmartGoalsDashboard = false
    
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
        .sheet(isPresented: $showFitnessTrends) {
            FitnessTrendsView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showNutritionAnalysis) {
            NutritionAnalysisView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showSleepPatterns) {
            SleepPatternsView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showHealthCorrelations) {
            HealthCorrelationsView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showExportReport) {
            ExportReportView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showShareInsights) {
            ShareInsightsView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showAIPredictions) {
            AIPredictionsView(analyticsService: analyticsService)
        }
        .sheet(isPresented: $showSmartGoalsDashboard) {
            SmartGoalsDashboardView(analyticsService: analyticsService)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            Task {
                await loadAnalytics()
                await analyticsService.loadTodayData()
            }
        }
    }
    
    // MARK: - Analytics Loading
    private func loadAnalytics() async {
        isLoading = true
        await analyticsService.analyzeTrends()
        await analyticsService.generatePredictions()
        await analyticsService.generateInsights()
        do {
            _ = try await analyticsService.analyzeCorrelations()
        } catch {
            print("AnalyticsView: Failed to analyze correlations: \(error)")
        }
        isLoading = false
    }
    
    private func refreshAnalytics() async {
        await loadAnalytics()
        await analyticsService.loadTodayData()
    }
}

// MARK: - Analytics View Sections
extension AnalyticsView {
    
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
                    value: analyticsService.todaySteps,
                    icon: "figure.walk",
                    color: .green,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: analyticsService.todayCalories,
                    icon: "flame.fill",
                    color: .orange,
                    theme: theme
                )
                
                QuickStatCard(
                    title: "Sleep",
                    value: analyticsService.lastNightSleep,
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
                .onTapGesture {
                    showFitnessTrends = true
                }
                
                AnalyticsCategoryCard(
                    title: "Nutrition Analysis",
                    description: "Understand your eating patterns",
                    icon: "fork.knife",
                    color: .orange,
                    theme: theme
                )
                .onTapGesture {
                    showNutritionAnalysis = true
                }
                
                AnalyticsCategoryCard(
                    title: "Sleep Patterns",
                    description: "Monitor your sleep quality",
                    icon: "moon.fill",
                    color: .purple,
                    theme: theme
                )
                .onTapGesture {
                    showSleepPatterns = true
                }
                
                AnalyticsCategoryCard(
                    title: "Health Correlations",
                    description: "Discover health connections",
                    icon: "chart.xyaxis.line",
                    color: .blue,
                    theme: theme
                )
                .onTapGesture {
                    showHealthCorrelations = true
                }
                
                AnalyticsCategoryCard(
                    title: "Smart Goals Dashboard",
                    description: "AI-powered goals & predictions",
                    icon: "target",
                    color: .indigo,
                    theme: theme
                )
                .onTapGesture {
                    showSmartGoalsDashboard = true
                }
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
                
                Button("AI Predictions") {
                    showAIPredictions = true
                }
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.primary)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(analyticsService.insights.prefix(3)), id: \.title) { insight in
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
                    action: { showExportReport = true },
                    theme: theme
                )
                
                QuickActionButton(
                    title: "Share Insights",
                    icon: "share",
                    color: .blue,
                    action: { showShareInsights = true },
                    theme: theme
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
}



// MARK: - Smart Goals Dashboard View
struct SmartGoalsDashboardView: View {
    let analyticsService: AnalyticsService
    @StateObject private var smartGoalsService: SmartGoalsService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var animateContent = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
        let healthService = HealthService()
        let authRepository = AuthRepository()
        let strapiRepository = StrapiRepository(authRepository: authRepository)
        self._smartGoalsService = StateObject(wrappedValue: SmartGoalsService(
            healthService: healthService,
            strapiRepository: strapiRepository,
            authRepository: authRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Picker
                tabPickerSection
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    goalsOverviewTab
                        .tag(0)
                    
                    dailyActionsTab
                        .tag(1)
                    
                    predictionsTab
                        .tag(2)
                    
                    progressTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(theme.background)
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            Task {
                await smartGoalsService.analyzeUserProfileAndSuggestGoals()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Smart Goals Dashboard")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("AI-powered wellness insights")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(action: {
                    // Refresh data
                    Task {
                        await smartGoalsService.analyzeUserProfileAndSuggestGoals()
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            theme.background
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    

    
    // MARK: - Tab Picker
    private var tabPickerSection: some View {
        let tabs = ["Goals", "Actions", "Predictions", "Progress"]
        
        return HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundColor(selectedTab == index ? theme.primary : theme.onSurfaceVariant)
                        
                        Rectangle()
                            .fill(selectedTab == index ? theme.primary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.surface)
    }
    
    // MARK: - Goals Overview Tab
    private var goalsOverviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if smartGoalsService.isLoading {
                    loadingView
                } else if smartGoalsService.currentGoal == nil {
                    emptyStateView(
                        icon: "target",
                        title: "No Smart Goals Set",
                        description: "Set up your health goals in Profile to get personalized insights"
                    )
                } else {
                    // Current Goal Section
                    currentGoalSection
                    
                    // Milestones Section
                    milestonesSection
                    
                    // Achievements Section
                    achievementsSection
                    
                    // Progress Insights Section
                    progressInsightsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Goals Tab Sections
    private var currentGoalSection: some View {
        guard let currentGoal = smartGoalsService.currentGoal else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Goal")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                        Text(currentGoal.type)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "target")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(theme.primary)
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Timeline")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Spacer()
                        
                        Text(currentGoal.timeline.description)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                    }
                    
                    HStack {
                        Text("Commitment")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Spacer()
                        
                        Text(currentGoal.commitment.description)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                    }
                    
                    HStack {
                        Text("Category")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Spacer()
                        
                        Text(currentGoal.category.description)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        )
    }
    
    private var milestonesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Milestones")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "flag.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            if smartGoalsService.milestones.isEmpty {
                emptyStateView(
                    icon: "flag",
                    title: "No Milestones Yet",
                    description: "Complete actions to unlock milestones"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(smartGoalsService.milestones, id: \.id) { milestone in
                        MilestoneRow(
                            title: milestone.title,
                            description: milestone.description,
                            date: formatDate(milestone.targetDate),
                            isCompleted: milestone.isAchieved,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var achievementsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)
            }
            
            if smartGoalsService.achievements.isEmpty {
                emptyStateView(
                    icon: "trophy",
                    title: "No Achievements Yet",
                    description: "Keep working towards your goals to earn achievements"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(smartGoalsService.achievements, id: \.id) { achievement in
                        AchievementRow(
                            title: achievement.title,
                            description: achievement.description,
                            date: formatDate(achievement.dateAchieved),
                            icon: getAchievementIcon(for: achievement.type),
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var progressInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            if smartGoalsService.progressInsights.isEmpty {
                emptyStateView(
                    icon: "lightbulb",
                    title: "No Insights Yet",
                    description: "Track your progress to get personalized insights"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(smartGoalsService.progressInsights, id: \.title) { insight in
                        InsightRow(
                            title: insight.title,
                            description: insight.message,
                            icon: insight.icon,
                            color: insight.type == .positive ? .green : insight.type == .negative ? .red : .blue,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Daily Actions Tab
    private var dailyActionsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if smartGoalsService.isLoading {
                    loadingView
                } else if smartGoalsService.dailyActions.isEmpty {
                    emptyStateView(
                        icon: "target",
                        title: "No Smart Goals Set",
                        description: "Set up your health goals in Profile to get personalized daily actions"
                    )
                } else {
                    // Today's Actions Header
                    todayActionsHeader
                    
                    // Action Categories
                    actionCategoriesSection
                    
                    // Completed Actions
                    completedActionsSection
                    
                    // Pending Actions
                    pendingActionsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .offset(x: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Predictions Tab
    private var predictionsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if smartGoalsService.isLoading {
                    loadingView
                } else if smartGoalsService.predictions.isEmpty {
                    emptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Predictions Yet",
                        description: "Set up your goals to get AI-powered predictions"
                    )
                } else {
                    // AI Predictions Header
                    predictionsHeader
                    
                    // Predictions List
                    predictionsList
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .offset(x: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            
            Text("Loading smart predictions...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.orange)
            
            Text("Oops! Something went wrong")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            Text(message)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await smartGoalsService.analyzeUserProfileAndSuggestGoals()
                }
            }
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primary)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Progress Tab
    private var progressTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if smartGoalsService.isLoading {
                    loadingView
                } else if smartGoalsService.dailyActions.isEmpty {
                    emptyStateView(
                        icon: "chart.bar.fill",
                        title: "No Progress Data",
                        description: "Complete actions to see your progress"
                    )
                } else {
                    // Progress Overview
                    progressOverviewSection
                    
                    // Daily Actions Progress
                    dailyActionsProgressSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .offset(x: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Predictions Sections
    private var predictionsList: some View {
        VStack(spacing: 16) {
            ForEach(smartGoalsService.predictions, id: \.title) { prediction in
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prediction.title)
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Text(prediction.description)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(prediction.confidence * 100))%")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text(prediction.timeframe)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                    
                    // Confidence bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(theme.onSurface.opacity(0.1))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(.blue)
                                .frame(width: geometry.size.width * prediction.confidence, height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
}

// MARK: - Smart Goals Dashboard View
extension SmartGoalsDashboardView {
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getAchievementIcon(for type: AchievementType) -> String {
        switch type {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar.badge.plus"
        case .milestone: return "flag.fill"
        case .special: return "star.fill"
        }
    }
    
    private func getPriorityValue(_ priority: ActionPriority) -> Int {
        switch priority {
        case .low: return 1
        case .medium: return 3
        case .high: return 5
        }
    }
}

// MARK: - Smart Goals Dashboard Section Views
extension SmartGoalsDashboardView {
    
    // MARK: - Current Goal Card
    private var currentGoalCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Goal")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Your primary wellness objective")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "target")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.indigo)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.indigo.opacity(0.15))
                    )
            }
            
            // Goal Details
            VStack(spacing: 12) {
                HStack {
                    Text("Goal Type")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Weight Management")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                HStack {
                    Text("Category")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Health & Longevity")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                HStack {
                    Text("Timeline")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("6 Months")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                HStack {
                    Text("Commitment")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("Dedicated")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Goal Progress Section
    private var goalProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Progress")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("65% Complete")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.onSurface.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.green)
                            .frame(width: geometry.size.width * 0.65, height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Started 3 months ago")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("3 months remaining")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    

    
    // MARK: - Today's Actions Header
    private var todayActionsHeader: some View {
        let completedActions = smartGoalsService.dailyActions.filter { $0.isCompleted }
        let totalActions = smartGoalsService.dailyActions.count
        let progressPercentage = totalActions > 0 ? Double(completedActions.count) / Double(totalActions) : 0.0
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Actions")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    if let currentGoal = smartGoalsService.currentGoal {
                        Text("Based on your \(currentGoal.type) goal")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                    } else {
                        Text("AI-generated daily tasks for your goals")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(completedActions.count)/\(totalActions)")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Completed")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(theme.onSurface.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: completedActions.count)
                
                Text("\(Int(progressPercentage * 100))%")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Action Categories Section
    private var actionCategoriesSection: some View {
        let actionCategories = calculateActionCategories()
        
        return VStack(spacing: 16) {
            Text("Action Categories")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            if actionCategories.isEmpty {
                emptyStateView(
                    icon: "list.bullet",
                    title: "No Action Categories",
                    description: "Start tracking your daily actions"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(actionCategories, id: \.title) { category in
                        DynamicActionCategoryCard(
                            title: category.title,
                            completedCount: category.completedCount,
                            totalCount: category.totalCount,
                            icon: category.icon,
                            color: category.color,
                            progress: category.progress,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func calculateActionCategories() -> [ActionCategoryData] {
        let actions = smartGoalsService.dailyActions
        
        // Group actions by type
        let nutritionActions = actions.filter { $0.type == .nutrition }
        let activityActions = actions.filter { $0.type == .activity || $0.type == .exercise }
        let sleepActions = actions.filter { $0.type == .sleep }
        let mindfulnessActions = actions.filter { $0.type == .mindfulness }
        let hydrationActions = actions.filter { $0.type == .hydration }
        let lifestyleActions = actions.filter { $0.type == .lifestyle || $0.type == .social }
        
        var categories: [ActionCategoryData] = []
        
        if !nutritionActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Nutrition",
                completedCount: nutritionActions.filter { $0.isCompleted }.count,
                totalCount: nutritionActions.count,
                icon: "fork.knife",
                color: .orange,
                progress: Double(nutritionActions.filter { $0.isCompleted }.count) / Double(nutritionActions.count)
            ))
        }
        
        if !activityActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Activity",
                completedCount: activityActions.filter { $0.isCompleted }.count,
                totalCount: activityActions.count,
                icon: "figure.run",
                color: .green,
                progress: Double(activityActions.filter { $0.isCompleted }.count) / Double(activityActions.count)
            ))
        }
        
        if !sleepActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Sleep",
                completedCount: sleepActions.filter { $0.isCompleted }.count,
                totalCount: sleepActions.count,
                icon: "moon.fill",
                color: .purple,
                progress: Double(sleepActions.filter { $0.isCompleted }.count) / Double(sleepActions.count)
            ))
        }
        
        if !mindfulnessActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Mindfulness",
                completedCount: mindfulnessActions.filter { $0.isCompleted }.count,
                totalCount: mindfulnessActions.count,
                icon: "brain.head.profile",
                color: .blue,
                progress: Double(mindfulnessActions.filter { $0.isCompleted }.count) / Double(mindfulnessActions.count)
            ))
        }
        
        if !hydrationActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Hydration",
                completedCount: hydrationActions.filter { $0.isCompleted }.count,
                totalCount: hydrationActions.count,
                icon: "drop.fill",
                color: .cyan,
                progress: Double(hydrationActions.filter { $0.isCompleted }.count) / Double(hydrationActions.count)
            ))
        }
        
        if !lifestyleActions.isEmpty {
            categories.append(ActionCategoryData(
                title: "Lifestyle",
                completedCount: lifestyleActions.filter { $0.isCompleted }.count,
                totalCount: lifestyleActions.count,
                icon: "heart.fill",
                color: .pink,
                progress: Double(lifestyleActions.filter { $0.isCompleted }.count) / Double(lifestyleActions.count)
            ))
        }
        
        return categories
    }
    
    private struct ActionCategoryData {
        let title: String
        let completedCount: Int
        let totalCount: Int
        let icon: String
        let color: Color
        let progress: Double
    }
    
    // MARK: - Completed Actions Section
    private var completedActionsSection: some View {
        let completedActions = smartGoalsService.dailyActions.filter { $0.isCompleted }
        
        return VStack(spacing: 16) {
            HStack {
                Text("Completed Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            
            if completedActions.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle",
                    title: "No Completed Actions",
                    description: "Complete your daily tasks to see them here"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(completedActions, id: \.id) { action in
                        DynamicActionRow(
                            title: action.title,
                            description: action.description,
                            time: action.target,
                            isCompleted: action.isCompleted,
                            priority: getPriorityValue(action.priority),
                            estimatedDuration: Int(action.target) ?? 0,
                            icon: action.icon,
                            color: action.color.toColor(),
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Pending Actions Section
    private var pendingActionsSection: some View {
        let pendingActions = smartGoalsService.dailyActions.filter { !$0.isCompleted }
        
        return VStack(spacing: 16) {
            HStack {
                Text("Pending Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            if pendingActions.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "All Actions Completed!",
                    description: "Great job! You've completed all your daily tasks"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(pendingActions, id: \.id) { action in
                        DynamicActionRow(
                            title: action.title,
                            description: action.description,
                            time: action.target,
                            isCompleted: action.isCompleted,
                            priority: getPriorityValue(action.priority),
                            estimatedDuration: Int(action.target) ?? 0,
                            icon: action.icon,
                            color: action.color.toColor(),
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Predictions Header
    private var predictionsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Predictions")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Machine learning insights for your wellness journey")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.purple.opacity(0.15))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Health Insights Section
    private var healthInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Health Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                InsightRow(
                    title: "Sleep Quality Impact",
                    description: "Better sleep correlates with 30% faster weight loss",
                    icon: "moon.fill",
                    color: .blue,
                    theme: theme
                )
                
                InsightRow(
                    title: "Workout Timing",
                    description: "Morning workouts show 25% better consistency",
                    icon: "sunrise.fill",
                    color: .orange,
                    theme: theme
                )
                
                InsightRow(
                    title: "Nutrition Balance",
                    description: "Protein timing affects muscle recovery by 40%",
                    icon: "leaf.fill",
                    color: .green,
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Weekly Progress Section
    private var weeklyProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progress")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("This Week")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            VStack(spacing: 12) {
                ProgressRow(
                    title: "Weight Change",
                    value: "-0.8kg",
                    trend: "↘️",
                    theme: theme
                )
                
                ProgressRow(
                    title: "Workouts",
                    value: "5/7",
                    trend: "✅",
                    theme: theme
                )
                
                ProgressRow(
                    title: "Calories Burned",
                    value: "+15%",
                    trend: "↗️",
                    theme: theme
                )
                
                ProgressRow(
                    title: "Sleep Quality",
                    value: "8.2/10",
                    trend: "↗️",
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    

    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        let completedActions = smartGoalsService.dailyActions.filter { $0.isCompleted }
        let totalActions = smartGoalsService.dailyActions.count
        let progressPercentage = totalActions > 0 ? Double(completedActions.count) / Double(totalActions) : 0.0
        
        return VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(completedActions.count)/\(totalActions)")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(theme.onSurface.opacity(0.1))
                        .frame(height: 12)
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(.green)
                        .frame(width: geometry.size.width * progressPercentage, height: 12)
                        .cornerRadius(6)
                        .animation(.easeInOut(duration: 0.5), value: progressPercentage)
                }
            }
            .frame(height: 12)
            
            Text("\(Int(progressPercentage * 100))% Complete")
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var dailyActionsProgressSection: some View {
        VStack(spacing: 16) {
            Text("Action Progress")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(smartGoalsService.dailyActions, id: \.id) { action in
                    actionProgressCard(action: action)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private func actionProgressCard(action: DailyAction) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: action.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(action.color.toColor())
                
                Text(action.title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .lineLimit(2)
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(theme.onSurface.opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(action.color.toColor())
                        .frame(width: geometry.size.width * action.progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("\(action.current)/\(action.target)")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Spacer()
                
                if action.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Empty State View
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(title)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
            
            Text(description)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Dynamic Smart Goals Components
struct DynamicPredictionRow: View {
    let title: String
    let description: String
    let confidence: String
    let timeframe: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(confidence)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text(timeframe)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DynamicProgressRow: View {
    let title: String
    let currentValue: String
    let targetValue: String
    let progress: Double
    let trend: String
    let unit: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(currentValue)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("/")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(targetValue)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(unit)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(trend)
                        .font(.system(size: 16))
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.onSurface.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}

struct DynamicTrendRow: View {
    let title: String
    let values: [String]
    let months: [String]
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                ForEach(Array(zip(months, values).enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        Text(data.0)
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Text(data.1)
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct DynamicMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Smart Goals Dashboard Supporting Views

struct MilestoneRow: View {
    let title: String
    let description: String
    let date: String
    let isCompleted: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isCompleted ? .green : theme.onSurfaceVariant)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(date)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.vertical, 8)
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let date: String
    let icon: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.yellow.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(date)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.vertical, 8)
    }
}

struct DynamicActionCategoryCard: View {
    let title: String
    let completedCount: Int
    let totalCount: Int
    let icon: String
    let color: Color
    let progress: Double
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(title)
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            Text("\(completedCount)/\(totalCount)")
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
            
            Text("Progress: \(Int(progress * 100))%")
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DynamicActionRow: View {
    let title: String
    let description: String
    let time: String
    let isCompleted: Bool
    let priority: Int
    let estimatedDuration: Int
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            VStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= priority ? color : theme.onSurface.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 20)
            
            // Action icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            // Action details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                        .strikethrough(isCompleted)
                    
                    Spacer()
                    
                    Text("\(estimatedDuration)m")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                    .strikethrough(isCompleted)
                
                HStack {
                    Text(time)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}

struct PredictionRow: View {
    let title: String
    let description: String
    let confidence: String
    let timeframe: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(confidence)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text(timeframe)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .padding(.vertical, 8)
    }
}




struct ProgressRow: View {
    let title: String
    let value: String
    let trend: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(trend)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 8)
    }
}

struct TrendRow: View {
    let title: String
    let january: String
    let february: String
    let march: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Jan")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(january)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                VStack(spacing: 4) {
                    Text("Feb")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(february)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                VStack(spacing: 4) {
                    Text("Mar")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(march)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            Text(value)
                .font(FitGlideTheme.titleMedium)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
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
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}




