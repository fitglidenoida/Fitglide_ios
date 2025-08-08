import SwiftUI

struct BrowseWorkoutPlansView: View {
    @StateObject private var planService: WorkoutPlanService
    @State private var selectedCategory: String = "All"
    @State private var showPremiumOnly = false
    @State private var searchText = ""
    @State private var showingPlanDetail: WorkoutEntry?
    @State private var showingMyPlans: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    init(showMyPlans: Bool = false) {
        let strapiRepository = StrapiRepository(authRepository: AuthRepository())
        let authRepository = AuthRepository()
        self._planService = StateObject(wrappedValue: WorkoutPlanService(strapiRepository: strapiRepository, authRepository: authRepository))
        self._showingMyPlans = State(initialValue: showMyPlans)
    }
    
    private let categories = ["All", "Running", "Strength", "Cardio", "Mixed", "Weight Loss"]
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Plan Type Toggle
                planTypeToggleSection
                
                // Filters
                filterSection
                
                // Plans List
                plansListSection
            }
            .background(theme.background)
            .navigationBarHidden(true)
        }
        .task {
            await planService.fetchAvailablePlans()
            await planService.fetchUserPlans()
        }
        .sheet(item: $showingPlanDetail) { plan in
            WorkoutPlanDetailView(plan: plan)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Plans")
                        .font(FitGlideTheme.titleLarge)
                        .foregroundColor(theme.onBackground)
                    
                    Text("Choose your fitness journey")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                // Premium Upgrade Button
                Button(action: {
                    // Premium upgrade action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("Upgrade")
                            .font(FitGlideTheme.bodyMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.primary)
                    .cornerRadius(16)
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.onSurfaceVariant)
                
                TextField("Search plans...", text: $searchText)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onBackground)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.surface)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Plan Type Toggle Section
    
    private var planTypeToggleSection: some View {
        HStack(spacing: 0) {
            Button(action: { showingMyPlans = false }) {
                Text("Available Plans")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(showingMyPlans ? theme.onSurfaceVariant : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(showingMyPlans ? Color.clear : theme.primary)
                    .cornerRadius(8)
            }
            
            Button(action: { showingMyPlans = true }) {
                Text("My Plans")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(showingMyPlans ? .white : theme.onSurfaceVariant)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(showingMyPlans ? .orange : Color.clear)
                    .cornerRadius(8)
            }
        }
        .background(theme.surface)
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(category)
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(selectedCategory == category ? .white : theme.onSurface)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? theme.primary : theme.surface)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Premium Toggle (only show for available plans)
            if !showingMyPlans {
                HStack {
                    Toggle("Premium Plans Only", isOn: $showPremiumOnly)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    if planService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Loading indicator for My Plans
                HStack {
                    Spacer()
                    
                    if planService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Plans List Section
    
    private var plansListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if planService.isLoading {
                    loadingView
                } else if filteredPlans.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredPlans) { plan in
                        WorkoutPlanCard(plan: plan) {
                            showingPlanDetail = plan
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading workout plans...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: showingMyPlans ? "heart" : "figure.run")
                .font(.system(size: 48))
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(showingMyPlans ? "No plans yet" : "No plans found")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onSurface)
            
            Text(showingMyPlans ? "Start a plan to see it here" : "Try adjusting your filters or search terms")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            if showingMyPlans {
                Button(action: {
                    showingMyPlans = false
                }) {
                    Text("Browse Available Plans")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(theme.primary)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredPlans: [WorkoutEntry] {
        let sourcePlans = showingMyPlans ? planService.userPlans : planService.availablePlans
        var plans = sourcePlans
        
        // Filter by category
        if selectedCategory != "All" {
            plans = plans.filter { $0.planCategory == selectedCategory }
        }
        
        // Filter by premium (only for available plans)
        if showPremiumOnly && !showingMyPlans {
            plans = plans.filter { $0.isPremium == true }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            plans = plans.filter { plan in
                plan.title.localizedCaseInsensitiveContains(searchText) ||
                plan.planName?.localizedCaseInsensitiveContains(searchText) == true ||
                plan.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return plans
    }
}

// MARK: - Workout Plan Card

struct WorkoutPlanCard: View {
    let plan: WorkoutEntry
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.planName ?? plan.title)
                            .font(FitGlideTheme.titleMedium)
                            .foregroundColor(theme.onBackground)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(plan.planLevel ?? "Beginner")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(levelColor)
                                .cornerRadius(8)
                            
                            if plan.isPremium == true {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                    Text("Premium")
                                        .font(FitGlideTheme.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(plan.planDurationWeeks ?? 4) weeks")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Text(plan.planCategory ?? "Mixed")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                }
                
                // Description
                if let description = plan.planDescription {
                    Text(description)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .lineLimit(2)
                }
                
                // Stats
                HStack(spacing: 16) {
                    StatItem(
                        icon: "clock",
                        value: "\(Int(plan.totalTimePlanned)) min",
                        label: "Duration"
                    )
                    
                    StatItem(
                        icon: "flame",
                        value: "\(Int(plan.caloriesPlanned)) cal",
                        label: "Calories"
                    )
                    
                    StatItem(
                        icon: "star.fill",
                        value: String(format: "%.1f", plan.planDifficultyRating ?? 0.0),
                        label: "Difficulty"
                    )
                }
            }
            .padding(16)
            .background(theme.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelColor: Color {
        switch plan.planLevel {
        case "Beginner":
            return .green
        case "Intermediate":
            return .orange
        case "Advanced":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(theme.primary)
                
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onBackground)
            }
            
            Text(label)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
    }
}

// MARK: - Workout Plan Detail View

struct WorkoutPlanDetailView: View {
    let plan: WorkoutEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var planService: WorkoutPlanService
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(plan: WorkoutEntry) {
        self.plan = plan
        let strapiRepository = StrapiRepository(authRepository: AuthRepository())
        let authRepository = AuthRepository()
        self._planService = StateObject(wrappedValue: WorkoutPlanService(strapiRepository: strapiRepository, authRepository: authRepository))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Plan Info
                    planInfoSection
                    
                    // Workout Details
                    workoutDetailsSection
                    
                    // Start Button
                    startButtonSection
                }
                .padding(20)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.planName ?? plan.title)
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(theme.onBackground)
            
            if let description = plan.planDescription {
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            HStack(spacing: 12) {
                Label("\(plan.planDurationWeeks ?? 4) weeks", systemImage: "calendar")
                Label(plan.planLevel ?? "Beginner", systemImage: "figure.run")
                Label(plan.planCategory ?? "Mixed", systemImage: "dumbbell")
            }
            .font(FitGlideTheme.bodyMedium)
            .foregroundColor(theme.onSurfaceVariant)
        }
    }
    
    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan Overview")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onBackground)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                InfoCard(title: "Duration", value: "\(Int(plan.totalTimePlanned)) min", icon: "clock")
                InfoCard(title: "Calories", value: "\(Int(plan.caloriesPlanned)) cal", icon: "flame")
                InfoCard(title: "Difficulty", value: String(format: "%.1f/5.0", plan.planDifficultyRating ?? 0.0), icon: "star.fill")
                InfoCard(title: "Weekly Calories", value: "\(plan.estimatedCaloriesPerWeek ?? 0) cal", icon: "chart.line.uptrend.xyaxis")
            }
        }
    }
    
    private var workoutDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Workout")
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onBackground)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(plan.title)
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(theme.onBackground)
                
                if let description = plan.description {
                    Text(description)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                HStack {
                    Label("Day \(plan.dayNumber)", systemImage: "calendar.badge.clock")
                    Spacer()
                    Label("Week \(plan.weekNumber ?? 1)", systemImage: "calendar.badge.plus")
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
            }
            .padding(16)
            .background(theme.surface)
            .cornerRadius(12)
        }
    }
    
    private var startButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await planService.startWorkoutPlan(plan: plan)
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start This Plan")
                }
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.primary)
                .cornerRadius(12)
            }
            
            if plan.isPremium == true {
                Text("Premium plan - Upgrade to access")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(theme.primary)
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(value)
                .font(FitGlideTheme.titleMedium)
                .foregroundColor(theme.onBackground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(theme.surface)
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    BrowseWorkoutPlansView()
} 
