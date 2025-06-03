//
//  HomeView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 9/06/25.
//

import SwiftUI
import Charts // For HydrationDetailsView

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
    
    let workoutMonitor = WorkoutMonitor()
    
    init(viewModel: HomeViewModel, date: Binding<Date>) {
        self.viewModel = viewModel
        self._date = date
        // Check if MaxMessage should be shown on app open
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
                mainScrollView
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
                    await checkAndShowDailyMaxMessage()
                }
            }

        }
    }
    

    
    private var mainScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection
                dateNavigationSection
                stepsSection
                healthMetricsSection
                navigationCardsSection
                maxInsightsSection
                challengesSection
                achievementsSection
                leaderboardSection
            }
            .padding(.vertical, 16)
        }
    }
    
    var headerSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.primary.opacity(0.9))
            Text("Hey \(viewModel.homeData.firstName)!")
                .font(.custom("Poppins-ExtraBold", size: 24))
                .foregroundColor(colors.onPrimary)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    var dateNavigationSection: some View {
        ZStack {
            dateNavBackground
            dateNavContent
        }
        .padding(.horizontal, 16)
    }
    
    private var dateNavBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.primary.opacity(0.4), lineWidth: 1)
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private var dateNavContent: some View {
        HStack {
            previousDateButton
            Spacer()
            dateText
            Spacer()
            nextDateButtons
        }
        .padding(12)
    }
    
    private var previousDateButton: some View {
        Button(action: {
            let interval = dateRangeMode == "Day" ? -24*60*60 : -7*24*60*60
            date = date.addingTimeInterval(TimeInterval(interval))
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.primary)
                .padding(8)
                .background(colors.surfaceVariant.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    private var dateText: some View {
        Text(dateDisplayText)
            .font(.custom("Poppins-Semibold", size: 16))
            .foregroundColor(colors.onSurface)
            .underline()
            .contextMenu {
                Button("Day") { dateRangeMode = "Day" }
                Button("Week") { dateRangeMode = "Week" }
                Button("Custom") {
                    showCustomPicker = true
                    selectingStartDate = true
                }
            }
    }
    
    private var nextDateButtons: some View {
        HStack(spacing: 8) {
            Button(action: {}) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.primary)
                    .padding(8)
                    .background(colors.surfaceVariant.opacity(0.3))
                    .clipShape(Circle())
            }
            Button(action: {
                let interval = dateRangeMode == "Day" ? 24*60*60 : 7*24*60*60
                date = date.addingTimeInterval(TimeInterval(interval))
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.primary)
                    .padding(8)
                    .background(colors.surfaceVariant.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
    
    var stepsSection: some View {
        ZStack {
            stepsBackground
            stepsContent
        }
        .padding(.horizontal, 16)
        .scaleEffect(isTracking ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTracking)
    }
    
    private var stepsBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            colors: [colors.primary.opacity(0.4), colors.secondary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private var stepsContent: some View {
        VStack {
            stepsProgressCircle
            stepsGoalText
            motivationalQuoteText
        }
        .padding(20)
    }
    
    private var stepsProgressCircle: some View {
        ZStack {
            Circle()
                .stroke(colors.primary.opacity(0.2), lineWidth: 12)
                .frame(width: 180, height: 180)
            stepsTrimmedCircle
            stepsInnerText
        }
    }
    
    private var stepsTrimmedCircle: some View {
        let progress = CGFloat(Float(viewModel.homeData.watchSteps) / viewModel.homeData.stepGoal).clamped(to: 0...1)
        return Circle()
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(
                    colors: [colors.primary, colors.secondary, colors.primary],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: 180, height: 180)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 1), value: viewModel.homeData.watchSteps)
    }
    
    private var stepsInnerText: some View {
        VStack {
            Text("\(Int(viewModel.homeData.watchSteps))")
                .font(.custom("Poppins-ExtraBold", size: 48))
                .foregroundColor(colors.primary)
            Text("Steps (\(dateRangeMode))")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(colors.onSurfaceVariant)
        }
    }
    
    private var stepsGoalText: some View {
        Text("Goal: \(Int(viewModel.homeData.stepGoal))")
            .font(.custom("Poppins-Regular", size: 14))
            .foregroundColor(colors.onSurfaceVariant)
            .padding(.top, 12)
    }
    
    private var motivationalQuoteText: some View {
        Text(motivationalQuote)
            .font(.custom("Poppins-Italic", size: 12))
            .foregroundColor(colors.onSurfaceVariant.opacity(0.8))
            .padding(.top, 4)
    }
    
    var healthMetricsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                heartRateMetric
                caloriesMetric
                stressMetric
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    private var heartRateMetric: some View {
        HealthMetricView(
            title: "Avg HR",
            value: "0/190",
            unit: "BPM",
            progress: 0.0,
            color: colors.secondary,
            colors: colors
        )
    }
    
    private var caloriesMetric: some View {
        let progress = Float(viewModel.homeData.caloriesBurned) / Float(viewModel.homeData.bmr)
        return HealthMetricView(
            title: "Calories",
            value: "\(Int(viewModel.homeData.caloriesBurned))/\(Int(viewModel.homeData.bmr))",
            unit: "Cal",
            progress: progress,
            color: colors.tertiary,
            colors: colors
        )
    }
    
    private var stressMetric: some View {
        HealthMetricView(
            title: "Stress",
            value: "Low",
            unit: "",
            progress: 0.0,
            color: colors.primary,
            colors: colors
        )
    }
    
    var navigationCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(navigationItems(), id: \.id) { item in
                navigationCard(for: item)
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func navigationCard(for item: NavigationItem) -> some View {
        if item.label.contains("Friends") {
            Button {
                showSocialTab = true
            } label: {
                NavigationCard(
                    icon: item.icon,
                    label: item.label,
                    colors: colors,
                    viewModel: viewModel,
                    onLogWater: nil
                )
            }

        } else if item.label.contains("Hydration") {
            NavigationCard(
                icon: item.icon,
                label: item.label,
                colors: colors,
                viewModel: viewModel,
                onLogWater: {
                    Task {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        print("Button tapped: Current hydration = \(viewModel.homeData.hydration)L")
                        print("Button tapped: Calling logWaterToStrapi with amount: 0.25")
                        await viewModel.logWaterToStrapi(amount: 0.25)
                        print("Button tapped: Calling logWaterIntake with amount: 0.25")
                        await viewModel.logWaterIntake(amount: 0.25)
                        print("Button tapped: Water log action completed, new hydration = \(viewModel.homeData.hydration)L")
                    }
                }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        showHydrationDetails = true
                        print("Hydration card tapped")
                    }
            )
        } else {
            NavigationCard(
                icon: item.icon,
                label: item.label,
                colors: colors,
                viewModel: viewModel,
                onLogWater: nil
            )
        }
    }
    
    var maxInsightsSection: some View {
        ZStack {
            insightsBackground
            insightsContent
        }
        .padding(.horizontal, 16)
    }
    
    private var insightsBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.primary.opacity(0.4), lineWidth: 1)
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private var insightsContent: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(colors.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.homeData.maxMessage.yesterday)")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(colors.onSurface)
                Text("\(viewModel.homeData.maxMessage.today)")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(colors.onSurfaceVariant)
            }
            Spacer()
            Button(action: {
                showMaxMessage = true
                print("Max message button tapped")
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.primary)
                    .padding(10)
                    .background(colors.surfaceVariant.opacity(0.4))
                    .clipShape(Circle())
                    .scaleEffect(showMaxMessage ? 1.1 : 1.0)
                    .animation(.spring(), value: showMaxMessage)
            }
        }
        .padding(16)
    }
    
    var challengesSection: some View {
        ZStack {
            challengesBackground
            challengesContent
        }
        .padding(.horizontal, 16)
    }
    
    private var challengesBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.primary.opacity(0.4), lineWidth: 1)
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    private var challengesContent: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(colors.primary)

            Text("Join a Step Challenge!")
                .font(.custom("Poppins-Medium", size: 16))
                .foregroundColor(colors.onSurface)

            Spacer()

            Button(action: {
                print("Navigating to Challenges View")
                navigateToChallenges = true
            }) {
                Text("Join")
                    .font(.custom("Poppins-Semibold", size: 14))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
    }

    var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(colors.onSurface)
            achievementsScrollView
        }
        .padding(.horizontal, 16)
    }
    
    private var achievementsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Text("No achievements earned")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding(16)
            }
            .padding(.horizontal, 16)
        }
        .background(achievementsBackground)
    }
    
    private var achievementsBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.primary.opacity(0.4), lineWidth: 1)
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real People. Real Progress.")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.weightLossStories.isEmpty {
                VStack(spacing: 16) {
                    Text("No success stories yet")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(colors.onSurface)
                    Button("Refresh") {
                        Task {
                            await viewModel.fetchWeightLossStories()
                        }
                    }
                    .font(.custom("Poppins-Semibold", size: 14))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(leaderboardBackground)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.weightLossStories, id: \.id) { story in
                            storyCard(for: story)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .background(leaderboardBackground)
            }
        }
        .padding(.horizontal, 16)
    }

    private func storyCard(for story: WeightLossStory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImage(url: URL(string: story.thenPhotoUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())

                AsyncImage(url: URL(string: story.nowPhotoUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            }

            Text("\(String(describing: story.firstName)) lost \(Int(story.weightLost ?? 0)) kg")
                .font(.custom("Poppins-Semibold", size: 14))
                .foregroundColor(colors.onSurface)

            Text(story.storyText ?? "")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(colors.onSurfaceVariant)
                .lineLimit(3)
        }
        .padding(12)
        .frame(width: 220)
        .background(colors.surface.opacity(0.9))
        .cornerRadius(12)
    }

    
    private var leaderboardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colors.surface.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colors.primary.opacity(0.4), lineWidth: 1)
            )
            .background(.regularMaterial)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }

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
    
    private var dateDisplayText: String {
        switch dateRangeMode {
        case "Day":
            return dateFormatter.string(from: date)
        case "Week":
            let start = date.addingTimeInterval(-6*24*60*60)
            return "Week of \(shortDateFormatter.string(from: start))-\(dateFormatter.string(from: date))"
        case "Custom":
            if let start = customStartDate, let end = customEndDate {
                return "\(shortDateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
            }
            return "Select Custom Range"
        default:
            return dateFormatter.string(from: date)
        }
    }
    
    
    
    private var workoutTypeIcon: String {
        switch workoutType {
        case "Walking": return "figure.walk"
        case "Running": return "figure.run"
        case "Cycling": return "bicycle"
        case "Hiking": return "mountain.2.fill"
        case "Swimming": return "drop.fill"
        case "Other": return "dumbbell.fill"
        default: return "dumbbell.fill"
        }
    }
    
    private var motivationalQuote: String {
        let quotes = [
            "Every step counts towards your goal!",
            "Keep moving, you're doing great!",
            "One step at a time, you're unstoppable!",
            "Your journey, your pace, your victory!"
        ]
        return quotes.randomElement() ?? "Keep moving!"
    }
    
    private let workoutTypes: [(name: String, icon: String)] = [
        ("Walking", "figure.walk"),
        ("Running", "figure.run"),
        ("Cycling", "bicycle"),
        ("Hiking", "mountain.2.fill"),
        ("Swimming", "drop.fill"),
        ("Other", "dumbbell.fill")
    ]
    
    private func navigationItems() -> [NavigationItem] {
        return [
            NavigationItem(
                icon: "figure.walk",
                label: "Workout - \(Int(viewModel.homeData.caloriesBurned)) cal"
            ),
            NavigationItem(
                icon: "bed.double.fill",
                label: String(format: "%.1fh slept", viewModel.homeData.sleepHours)
            ),
            NavigationItem(
                icon: "fork.knife",
                label: "\(Int(viewModel.homeData.caloriesLogged))/\(viewModel.homeData.bmr) cal"
            ),
            NavigationItem(
                icon: "drop.fill",
                label: "Hydration - \(String(format: "%.1f", viewModel.homeData.hydration))L / \(String(format: "%.1f", viewModel.homeData.hydrationGoal))L"
            ),
            NavigationItem(
                icon: "person.2.fill",
                label: "Friends & Social"
            ),
        ]
    }

    struct NavigationItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
    }
    
    struct NavigationCard: View {
        let icon: String
        let label: String
        let colors: FitGlideTheme.Colors
        let viewModel: HomeViewModel
        let onLogWater: (() -> Void)?
        
        var body: some View {
            let isHydrationCard = label.contains("Hydration")
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.primary.opacity(0.4), lineWidth: 1)
                    )
                    .background(.regularMaterial)
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(label)
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(colors.onSurface)
                        
                        if isHydrationCard {
                            ProgressView(value: viewModel.homeData.hydration, total: viewModel.homeData.hydrationGoal)
                                .progressViewStyle(.linear)
                                .tint(colors.primary)
                                .background(colors.surfaceVariant.opacity(0.3))
                                .frame(height: 8)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    
                    Spacer()
                    
                    if isHydrationCard, let onLogWater = onLogWater {
                        Button(action: {
                            print("Log water button tapped")
                            onLogWater()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 22))
                                .foregroundColor(colors.primary)
                                .padding(8)
                                .background(colors.surfaceVariant.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    struct HealthMetricView: View {
        let title: String
        let value: String
        let unit: String
        let progress: Float
        let color: Color
        let colors: FitGlideTheme.Colors
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress).clamped(to: 0...1))
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.custom("Poppins-Semibold", size: 14))
                        .foregroundColor(colors.onSurface)
                    Text("\(title)\(unit.isEmpty ? "" : " (\(unit))")")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.primary.opacity(0.4), lineWidth: 1)
                    )
                    .background(.regularMaterial)
            )
        }
    }
    
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
    
    private var socialTabSheetContent: some View {
        let authRepository = AuthRepository()
        let strapiRepository = StrapiRepository(authRepository: authRepository)
        let packsVM = PacksViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let challengesVM = ChallengesViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let friendsVM = FriendsViewModel(strapiRepository: strapiRepository, authRepository: authRepository)
        let cheersVM = CheersViewModel(strapiRepository: strapiRepository, authRepository: authRepository, workoutMonitor: workoutMonitor)

        return SocialTabView(
            packsViewModel: packsVM,
            challengesViewModel: challengesVM,
            friendsViewModel: friendsVM,
            cheersViewModel: cheersVM
        )
    }

    
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


