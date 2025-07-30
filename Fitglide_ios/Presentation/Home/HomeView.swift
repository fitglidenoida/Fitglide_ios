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
    @State private var showSocialTab: Bool = false
    @State private var navigateToProfile = false
    @State private var navigateToPeriods = false
    @State private var showAddPeriod = false
    @State private var showAddSymptom = false

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
    
    // WorkoutMonitor removed - live tracking handled by Watch app
    
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
                colors.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Section
                        headerSection
                        
                        // Date Navigation
                        dateNavigationSection
                        
                        // Profile Setup Banner
                        ProfileSetupBanner(
                            profileData: {
                                if let vitals = viewModel.healthVitals.first {
                                    return ProfileData(
                                        firstName: viewModel.homeData.firstName,
                                        lastName: "",
                                        height: Float(vitals.height ?? 0),
                                        weight: Float(vitals.WeightInKilograms ?? 0),
                                        age: 0,
                                        activityLevel: vitals.activity_level ?? "",
                                        fitnessGoal: vitals.weight_loss_strategy ?? ""
                                    )
                                } else {
                                    return nil
                                }
                            }(),
                            colorScheme: colorScheme,
                            onSetupTap: {
                                navigateToProfile = true
                            }
                        )
                        
                        // Main Steps Card
                        stepsSection
                        
                        // Cycle Tracking Card (for users who have periods)
                        cycleTrackingSection
                        
                        // Health Metrics
                        healthMetricsSection
                        
                        // Hydration & Social Section
                        hydrationSocialSection
                        
                        // Max's Insights
                        maxInsightsSection
                        
                        // Badges Section
                        badgesSection
                        
                        // Challenges Section
                        challengesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .sheet(isPresented: $showCustomPicker) {
                customDatePickerContent
            }
            .navigationDestination(isPresented: $navigateToChallenges) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let challengesVM = ChallengesViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
                ChallengesView(viewModel: challengesVM)
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let profileVM = ProfileViewModel(strapiRepository: strapiRepo, authRepository: authRepo, healthService: HealthService())
                let stravaAuthVM = StravaAuthViewModel( authRepository: authRepo)
                let navigationVM = NavigationViewModel()
                ProfileView(
                    viewModel: profileVM,
                    stravaAuthViewModel: stravaAuthVM,
                    navigationViewModel: navigationVM,
                    authRepository: authRepo
                )
            }
            .navigationDestination(isPresented: $navigateToPeriods) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let healthService = HealthService()
                let periodsVM = PeriodsViewModel(healthService: healthService, strapiRepository: strapiRepo, authRepository: authRepo)
                NavigationView {
                    PeriodsView(viewModel: periodsVM)
                        .navigationTitle("Cycle Tracking")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .sheet(isPresented: $showAddPeriod) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let healthService = HealthService()
                let periodsVM = PeriodsViewModel(healthService: healthService, strapiRepository: strapiRepo, authRepository: authRepo)
                NavigationView {
                    AddPeriodView(viewModel: periodsVM)
                        .navigationTitle("Log Period")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showAddSymptom) {
                let authRepo = AuthRepository()
                let strapiRepo = StrapiRepository(authRepository: authRepo)
                let healthService = HealthService()
                let periodsVM = PeriodsViewModel(healthService: healthService, strapiRepository: strapiRepo, authRepository: authRepo)
                NavigationView {
                    AddSymptomView(viewModel: periodsVM)
                        .navigationTitle("Add Symptom")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showSocialTab) {
                socialTabSheetContent
            }
            .alert(isPresented: $showMaxMessage) {
                Alert(
                    title: Text("Max Says"),
                    message: Text("\(viewModel.homeData.maxMessage.yesterday)\n\n \(viewModel.homeData.maxMessage.today)"),
                    dismissButton: .default(Text("Let's Go!")) {
                        showMaxMessage = false
                        if !hasShownDailyMessage {
                            viewModel.markMaxMessagePlayed()
                            UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: "lastMaxMessageDate")
                            UserDefaults.standard.synchronize()
                        }
                    }
                )
            }
            .overlay(
                HomeFloatingActionButtonView(isTracking: $isTracking, theme: colors, action: { isTracking.toggle() })
                    .padding(.bottom, 16)
                    .padding(.trailing, 16),
                alignment: .bottomTrailing
            )
            .onChange(of: date) {
                viewModel.updateDate(date)
            }
            .onAppear {
                Task {
                    await viewModel.refreshData()
                    await checkAndShowDailyMaxMessage()
                }
            }
            .refreshable {
                Task {
                    await viewModel.refreshData()
                }
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        // Greeting Banner - Full width
        HStack {
            Text("Hey \(viewModel.homeData.firstName)!")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(colors.onPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.primary)
        )
        .shadow(color: colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Date Navigation
    var dateNavigationSection: some View {
        HStack {
            Button(action: {
                let interval = dateRangeMode == "Day" ? -24*60*60 : -7*24*60*60
                date = date.addingTimeInterval(TimeInterval(interval))
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.primary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(shortDateFormatter.string(from: date))
                    .font(.custom("Poppins-Semibold", size: 16))
                    .foregroundColor(colors.primary)
                
                Button(action: {
                    showCustomPicker = true
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colors.primary)
                }
            }
            
            Spacer()
            
            Button(action: {
                let interval = dateRangeMode == "Day" ? 24*60*60 : 7*24*60*60
                date = date.addingTimeInterval(TimeInterval(interval))
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Steps Section
    var stepsSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(colors.primary.opacity(0.15), lineWidth: 16)
                    .frame(width: 200, height: 200)
                
                let progress = CGFloat(Float(viewModel.homeData.watchSteps) / viewModel.homeData.stepGoal).clamped(to: 0...1)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: viewModel.homeData.watchSteps)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.homeData.watchSteps))")
                        .font(.custom("Poppins-Bold", size: 48))
                        .foregroundColor(colors.primary)
                    Text("Steps (Day)")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
            
            VStack(spacing: 8) {
                Text("Goal: \(Int(viewModel.homeData.stepGoal))")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(colors.onSurfaceVariant)
                
                Text("You've got this!")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(colors.onSurfaceVariant.opacity(0.8))
                    .italic()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Health Metrics (Real Data)
    var healthMetricsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                healthMetricCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "0/190",
                    unit: "BPM",
                    progress: 0.0
                )
                
                healthMetricCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(Int(viewModel.homeData.caloriesBurned))/\(Int(viewModel.homeData.bmr))",
                    unit: "Cal",
                    progress: CGFloat(viewModel.homeData.caloriesBurned) / CGFloat(viewModel.homeData.bmr)
                )
                
                healthMetricCard(
                    icon: "brain.head.profile",
                    title: "Stress",
                    value: "Low",
                    unit: "",
                    progress: 0.0
                )
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 140)
    }
    
    private func healthMetricCard(icon: String, title: String, value: String, unit: String, progress: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Text(title)
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 6) {
                Text(value)
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(colors.onSurface)
                
                Text(unit)
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(colors.onSurfaceVariant)
                
                Spacer()
            }
            
            Rectangle()
                .fill(colors.primary.opacity(progress))
                .frame(height: 6)
                .cornerRadius(3)
        }
        .padding(24)
        .frame(width: 200, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.primary.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Hydration & Social Section
    var hydrationSocialSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(colors.onSurface)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Hydration Card
                Button(action: { showHydrationDetails = true }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(colors.primary)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hydration")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(colors.onSurface)
                            
                            Text("\(String(format: "%.1f", viewModel.homeData.hydration))L / \(String(format: "%.1f", viewModel.homeData.hydrationGoal))L")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                        
                        ProgressView(value: viewModel.homeData.hydration, total: viewModel.homeData.hydrationGoal)
                            .progressViewStyle(.linear)
                            .tint(colors.primary)
                            .frame(height: 6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Social Card
                Button(action: { showSocialTab = true }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(colors.primary)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Social")
                                .font(.custom("Poppins-Bold", size: 16))
                                .foregroundColor(colors.onSurface)
                            
                            Text("Connect with friends")
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Max's Insights
    var maxInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Max's Insights")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button(action: {
                    showMaxMessage = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colors.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                insightCard(
                    title: "Yesterday",
                    message: viewModel.homeData.maxMessage.yesterday
                )
                
                insightCard(
                    title: "Today",
                    message: viewModel.homeData.maxMessage.today,
                    emoji: "💪"
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func insightCard(title: String, message: String, emoji: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(colors.primary)
                Spacer()
            }
            
            HStack {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(colors.onSurface)
                
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Badges Section (Simple Icons - No Cards)
    var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Badges")
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Text("2")
                    .font(.custom("Poppins-Bold", size: 16))
                    .foregroundColor(colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Sample badges - replace with actual badge data when available
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(colors.primary.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(colors.primary)
                        }
                        
                        Text("Thali Tandoor")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundColor(colors.onSurface)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(colors.secondary.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(colors.secondary)
                        }
                        
                        Text("Zen Beast")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundColor(colors.onSurface)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 100)
        }
    }
    
    // MARK: - Challenges Section
    var challengesSection: some View {
        Button(action: {
            navigateToChallenges = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Challenges")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(colors.onSurface)
                    
                    Spacer()
                    
                    Text("View All")
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(colors.primary)
                }
                
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("No challenges yet")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(colors.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Custom Date Picker
    var customDatePickerContent: some View {
        VStack(spacing: 20) {
            Text(selectingStartDate ? "Pick Start Date" : "Pick End Date")
                .font(.custom("Poppins-Semibold", size: 18))
                .foregroundColor(colors.onSurface)
            DatePicker(
                "",
                selection: $date,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .accentColor(colors.primary)
            .padding(.horizontal)
            customPickerButtons
        }
        .padding(.vertical, 20)
        .background(colors.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
    
    private var customPickerButtons: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                showCustomPicker = false
            }
            .font(.custom("Poppins-Medium", size: 14))
            .foregroundColor(colors.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(colors.surfaceVariant.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            Spacer()
            Button(selectingStartDate ? "Select Start" : "Select End") {
                if selectingStartDate {
                    customStartDate = date
                    selectingStartDate = false
                } else {
                    customEndDate = date
                    dateRangeMode = "Custom"
                    showCustomPicker = false
                    selectingStartDate = true
                }
            }
            .font(.custom("Poppins-Medium", size: 14))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Cycle Tracking Section
    var cycleTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(colors.secondary)
                    .font(.title2)
                
                Text("Cycle Tracking")
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button("View Details") {
                    navigateToPeriods = true
                }
                .font(FitGlideTheme.caption)
                .foregroundColor(colors.primary)
            }
            
            HStack(spacing: 20) {
                // Current Cycle Day
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(viewModel.cycleDay)")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                    
                    Text("Current Cycle")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
                
                // Next Period
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(viewModel.daysUntilNextPeriod) days")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.secondary)
                    
                    Text("Until Next Period")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
            
            // Cycle Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cycle Progress")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("\(viewModel.cycleProgressPercentage)%")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.secondary)
                }
                
                ProgressView(value: viewModel.cycleProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: colors.secondary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showAddPeriod = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Log Period")
                            .font(FitGlideTheme.caption)
                    }
                    .foregroundColor(colors.onPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.secondary)
                    .clipShape(Capsule())
                }
                
                Button(action: { showAddSymptom = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.circle.fill")
                            .font(.caption)
                        Text("Add Symptom")
                            .font(FitGlideTheme.caption)
                    }
                    .foregroundColor(colors.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Floating Action Button
    struct HomeFloatingActionButtonView: View {
        @Binding var isTracking: Bool
        let theme: FitGlideTheme.Colors
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Image(systemName: isTracking ? "stop.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.onPrimary)
                    .padding(20)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [isTracking ? theme.secondary : theme.primary, theme.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(isTracking ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTracking)
            }
        }
    }
    
    // MARK: - Social Tab Sheet
    private var socialTabSheetContent: some View {
        let authRepository = AuthRepository()
        let strapiRepository = StrapiRepository(authRepository: authRepository)
        let packsVM = PacksViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let challengesVM = ChallengesViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let friendsVM = FriendsViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let cheersVM = CheersViewModel(strapiRepository: strapiRepository, authRepository: authRepository)

        return SocialTabView(
            packsViewModel: packsVM,
            challengesViewModel: challengesVM,
            friendsViewModel: friendsVM,
            cheersViewModel: cheersVM
        )
    }

    // MARK: - Preview
    struct HomeView_Previews: PreviewProvider {
        static var previews: some View {
            let authRepo = AuthRepository(appleAuthManager: AppleAuthManager())
            let strapiRepo = StrapiRepository(api: StrapiApiClient(), authRepository: authRepo)
            let healthService = HealthService()
            
            let viewModel = HomeViewModel(
                strapiRepository: strapiRepo,
                authRepository: authRepo,
                healthService: healthService
            )
            
            let previewDate = Binding.constant(Date())
            
            return HomeView(viewModel: viewModel, date: previewDate)
                .previewDisplayName("Home View Preview")
        }
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}
