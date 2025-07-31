//
//  HomeView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 9/06/25.
//

import SwiftUI
import Charts

@MainActor
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var date: Date
    @Environment(\.colorScheme) var colorScheme
    @State private var dateRangeMode = "Day"
    @State private var customStartDate: Date? = nil
    @State private var customEndDate: Date? = nil
    @State private var showCustomPicker = false
    @State private var selectingStartDate = true
    @State private var isTracking = false
    @State private var paused = false
    @State private var workoutType = "Walking"
    @State private var showMaxMessage = false
    @State private var showHydrationDetails = false
    @State private var hasShownDailyMessage = false
    @State private var navigateToChallenges = false
    @State private var navigateToPeriods = false
    @State private var showAddPeriod = false
    @State private var showAddSymptom = false
    @State private var showModernDesignSamples = false
    @State private var animateContent = false
    @State private var showMotivationalQuote = false

    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    init(viewModel: HomeViewModel, date: Binding<Date>) {
        self.viewModel = viewModel
        self._date = date
    }
    
    private func checkAndShowDailyMaxMessage() async {
        if !viewModel.homeData.maxMessage.hasPlayed {
            await viewModel.fetchMaxMessage()
            showMaxMessage = true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header Section (Stationary)
                    modernHeaderSection
                    
                    // Main Content
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 24) {
                            // Motivational Quote (Indian focused)
                            if showMotivationalQuote {
                                indianMotivationalQuoteCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Enhanced Steps Section
                            modernStepsSection
                            
                            // Health Metrics Grid
                            modernHealthMetricsGrid
                            
                            // Community Challenges Section
                            communityChallengesSection
                            
                            // Cycle Tracking Section
                            cycleTrackingSection
                            
                            // Wellness Insights Section
                            wellnessInsightsSection
                            
                            // Quick Actions Section
                            modernQuickActionsSection
                            
                            // Modern Design Sample Button (Temporary)
                            modernDesignSampleButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show motivational quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToChallenges) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let challengesVM = ChallengesViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                ChallengesView(viewModel: challengesVM)
            }

            .navigationDestination(isPresented: $navigateToPeriods) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let periodsVM = PeriodsViewModel(healthService: HealthService(), strapiRepository: strapiRepo, authRepository: authRepo)
                PeriodsView(viewModel: periodsVM)
            }

            .sheet(isPresented: $showAddPeriod) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let periodsVM = PeriodsViewModel(healthService: HealthService(), strapiRepository: strapiRepo, authRepository: authRepo)
                AddPeriodView(viewModel: periodsVM)
            }
            .sheet(isPresented: $showAddSymptom) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let periodsVM = PeriodsViewModel(healthService: HealthService(), strapiRepository: strapiRepo, authRepository: authRepo)
                AddSymptomView(viewModel: periodsVM)
            }
            .sheet(isPresented: $showHydrationDetails) {
                // Placeholder for hydration details
                Text("Hydration Details")
                    .font(.title)
                    .padding()
            }
            .sheet(isPresented: $showMaxMessage) {
                // Placeholder for max message
                Text("Max Message")
                    .font(.title)
                    .padding()
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
            VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Namaste \(viewModel.homeData.firstName)! 🙏")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Ready to make today amazing?")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Date Selector
            modernDateSelector
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Modern Date Selector
    var modernDateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let isSelected = Calendar.current.isDate(self.date, inSameDayAs: date)
                    
                    Button(action: { self.date = date }) {
                        VStack(spacing: 4) {
                            Text(dayOfWeek(for: date))
                                .font(FitGlideTheme.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? colors.onPrimary : colors.onSurfaceVariant)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? colors.onPrimary : colors.onSurface)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? colors.primary : (isToday ? colors.primary.opacity(0.1) : colors.surface))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday && !isSelected ? colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(offset + 3) * 0.05), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Indian Motivational Quote Card
    var indianMotivationalQuoteCard: some View {
        VStack(spacing: 12) {
        HStack {
                Image(systemName: "quote.bubble.fill")
                .font(.title2)
                .foregroundColor(colors.primary)
                
            Spacer()
                
                Text("Daily Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Text(indianQuotes.randomElement() ?? indianQuotes[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(colors.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Modern Steps Section
    var modernStepsSection: some View {
        VStack(spacing: 16) {
        HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps Today")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)
                    
                    Text("Keep moving, keep growing")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(viewModel.homeData.watchSteps))")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.primary)
                    
                    Text("of \(Int(viewModel.homeData.stepGoal))")
                        .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
                }
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.surfaceVariant)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.8 * progress, height: 8)
                    .scaleEffect(x: animateContent ? 1.0 : 0.0, anchor: .leading)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
        .onTapGesture {
            // Show detailed steps view
            print("Steps detail tapped")
        }
    }
    
    // MARK: - Modern Health Metrics Grid
    var modernHealthMetricsGrid: some View {
        HStack(spacing: 12) {
            ModernHealthMetricCard(
                title: "Heart Rate",
                value: "\(viewModel.homeData.heartRate)",
                unit: "bpm",
                icon: "heart.fill",
                color: .red,
                theme: colors,
                animateContent: $animateContent,
                delay: 0.2
            )
            
            ModernHealthMetricCard(
                title: "Calories",
                value: "\(viewModel.homeData.caloriesBurned)",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange,
                theme: colors,
                animateContent: $animateContent,
                delay: 0.3
            )
            
            ModernHealthMetricCard(
                title: "Active Time",
                value: "45", // Hardcoded for now
                unit: "min",
                icon: "clock.fill",
                color: .blue,
                theme: colors,
                animateContent: $animateContent,
                delay: 0.4
            )
        }
    }
    
    // MARK: - Community Challenges Section
    var communityChallengesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Community Challenges")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button("View All") {
                    navigateToChallenges = true
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        CommunityChallengeCard(
                            title: ["Step Challenge", "Fitness Streak", "Wellness Week"][index],
                            participants: ["1.2K", "856", "432"][index],
                            progress: [0.7, 0.5, 0.3][index],
                            theme: colors,
                            animateContent: $animateContent,
                            delay: 0.5 + Double(index) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    

    
    // MARK: - Wellness Insights Section
    var wellnessInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Wellness Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                WellnessInsightCard(
                    title: "Sleep Quality",
                    value: "Good",
                    icon: "moon.fill",
                    color: .purple,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.6
                )
                
                WellnessInsightCard(
                    title: "Hydration",
                    value: "75%", // Hardcoded for now
                    icon: "drop.fill",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.7
                )
                
                WellnessInsightCard(
                    title: "Stress Level",
                    value: "Low",
                    icon: "brain.head.profile",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.8
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Cycle Tracking Section
    var cycleTrackingSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cycle Tracking")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)
            
                    Text("Track your wellness journey")
                        .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
                
                Button("View Details") {
                    navigateToPeriods = true
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            VStack(spacing: 12) {
                // Cycle Progress Card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(colors.surfaceVariant, lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.cycleProgress)
                            .stroke(colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(viewModel.cycleDay)")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(colors.primary)
                            
                            Text("Day")
                                .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
                        }
                    }
                    
                VStack(alignment: .leading, spacing: 4) {
                        Text("Cycle Day \(viewModel.cycleDay)")
                            .font(FitGlideTheme.bodyLarge)
                            .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)
                    
                        Text("\(viewModel.daysUntilNextPeriod) days until next period")
                            .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                
                        Text("\(viewModel.cycleProgressPercentage)% complete")
                            .font(FitGlideTheme.caption)
                    .foregroundColor(colors.primary)
            }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surface)
                        .shadow(color: colors.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
                )
                
                // Quick Actions
                HStack(spacing: 12) {
                    Button(action: { showAddPeriod = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Log Period")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.medium)
                        }
                    .foregroundColor(colors.primary)
        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors.primary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showAddSymptom = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Log Symptom")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
            .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Modern Quick Actions Section
    var modernQuickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                HomeModernQuickActionButton(
                    title: "Start Workout",
                    icon: "play.circle.fill",
                    color: colors.primary,
                    action: { /* Start workout */ },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.9
                )
                
                HomeModernQuickActionButton(
                    title: "Log Meal",
                    icon: "fork.knife",
                    color: .orange,
                    action: { /* Log meal */ },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.0
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
    }
    
    // MARK: - Modern Design Sample Button (Temporary)
    var modernDesignSampleButton: some View {
        Button(action: {
            showModernDesignSamples = true
        }) {
        HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                .foregroundColor(colors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Modern Design Samples Ready!")
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)

                    Text("Tap to see the new UI direction")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colors.onSurfaceVariant)
                }
                .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showModernDesignSamples) {
            ModernDesignSamplesView()
        }
    }
    
    // MARK: - Helper Properties
    private var progress: Double {
        min(Double(viewModel.homeData.watchSteps) / Double(viewModel.homeData.stepGoal), 1.0)
    }
    
    private var indianQuotes: [String] {
        [
            "Health is wealth - your body is your temple.",
            "Every step you take brings you closer to your goals.",
            "Strength comes from within, just like your spirit.",
            "Today's effort is tomorrow's achievement.",
            "Your wellness journey is a celebration of life."
        ]
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ModernHealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct CommunityChallengeCard: View {
    let title: String
    let participants: String
    let progress: Double
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("\(participants) participants")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(theme.surfaceVariant, lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(16)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct SocialCard: View {
    let title: String
    let subtitle: String
        let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
        
        var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                    Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
                .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct WellnessInsightCard: View {
        let title: String
        let value: String
    let icon: String
        let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
        
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
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                    Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct HomeModernQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
        let action: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
        
        var body: some View {
            Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct ModernDesignSamplesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedSample = 0
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Modern Design Samples")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Sample Selector
                HStack(spacing: 0) {
                    Button("Social Tab") {
                        selectedSample = 0
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedSample == 0 ? theme.primary.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedSample == 0 ? theme.primary : theme.onSurfaceVariant)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(selectedSample == 0 ? .semibold : .medium)
                    
                    Button("Workout Sample") {
                        selectedSample = 1
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedSample == 1 ? theme.primary.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedSample == 1 ? theme.primary : theme.onSurfaceVariant)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(selectedSample == 1 ? .semibold : .medium)
                }
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Content
                TabView(selection: $selectedSample) {
                    // Social Tab Sample
                    let authRepo = AuthRepository()
                    let strapiRepo = StrapiRepository(authRepository: authRepo)
                    let packsVM = PacksViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                    let challengesVM = ChallengesViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                    let friendsVM = FriendsViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                    let cheersVM = CheersViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                    
                    SocialTabView(
                        packsViewModel: packsVM,
                        challengesViewModel: challengesVM,
                        friendsViewModel: friendsVM,
                        cheersViewModel: cheersVM
                    )
                    .tag(0)
                    
                    // Workout Sample
                    ModernWorkoutSample()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(theme.background.ignoresSafeArea())
        }
    }
}


