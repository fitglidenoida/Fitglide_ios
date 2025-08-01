//
//  ProfileView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//


import HealthKit
import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @ObservedObject var stravaAuthViewModel: StravaAuthViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    let authRepository: AuthRepository
    @Environment(\.colorScheme) var colorScheme
    @State private var isPersonalDataExpanded = true
    @State private var isHealthVitalsExpanded = false
    @State private var isFitnessBridgeExpanded = false
    @State private var isSetGoalsExpanded = false
    @State private var isSettingsExpanded = false
    @State private var isLegalExpanded = false
    @State private var showDatePicker = false
    @State private var isLoading = false
    @State private var animateContent = false
    @State private var showWellnessQuote = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountAlert = false
    @State private var deleteAccountMessage = ""
    @State private var isDeletingAccount = false
    
    // Navigation state
    @State private var showMemberSinceDetail = false
    @State private var showWellnessScoreDetail = false
    @State private var showAchievementsDetail = false
    @State private var showStressLevelDetail = false
    @State private var showSettingsView = false

    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }

    private var areHealthVitalsValid: Bool {
        viewModel.profileData.weight != nil &&
        viewModel.profileData.height != nil &&
        !(viewModel.profileData.gender?.isEmpty ?? true) &&
        !(viewModel.profileData.dob?.isEmpty ?? true) &&
        !(viewModel.profileData.activityLevel?.isEmpty ?? true)
    }

    private var areGoalsValid: Bool {
        viewModel.profileData.weightLossGoal != nil &&
        !(viewModel.profileData.weightLossStrategy?.isEmpty ?? true)
    }

    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header Section
                        modernHeaderSection
                        
                        // Wellness Quote
                        if showWellnessQuote {
                            indianWellnessQuoteCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Profile Stats Overview
                        profileStatsOverview
                        
                        // Personal Information
                        personalInformationSection
                        
                        // Health & Wellness
                        healthWellnessSection
                        
                        // Achievements & Goals
                        achievementsGoalsSection
                        
                        // Connected Services
                        connectedServicesSection
                        
                        // Settings & Preferences
                        settingsPreferencesSection
                        
                        // Account Actions
                        accountActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $showDeleteAccountConfirmation) {
                DeleteAccountConfirmationView(
                    isPresented: $showDeleteAccountConfirmation,
                    onConfirm: {
                        showDeleteAccountConfirmation = false
                        Task {
                            await performAccountDeletion()
                        }
                    }
                )
            }
            .sheet(isPresented: $showMemberSinceDetail) {
                MemberSinceDetailView()
            }
            .sheet(isPresented: $showWellnessScoreDetail) {
                WellnessScoreDetailView()
            }
            .sheet(isPresented: $showAchievementsDetail) {
                AchievementsDetailView()
            }
            .sheet(isPresented: $showStressLevelDetail) {
                StressLevelDetailView()
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView(viewModel: viewModel)
            }
            .alert("Account Deletion", isPresented: $showDeleteAccountAlert) {
                Button("OK") {
                    showDeleteAccountAlert = false
                    if deleteAccountMessage.contains("successfully") {
                        // Navigate to login or restart app
                        authRepository.logout()
                    }
                }
            } message: {
                Text(deleteAccountMessage)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show wellness quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showWellnessQuote = true
                    }
                }
            }
            .alert(item: Binding(
                get: { viewModel.uiMessage.map { IdentifiableString(value: $0) } },
                set: { _ in viewModel.uiMessage = nil }
            )) { message in
                Alert(title: Text("Profile Update"), message: Text(message.value), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Profile 🙏")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Your wellness journey starts here")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }

                Spacer()
                
                // Profile Avatar
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    Text(viewModel.profileData.firstName?.first.map { String($0) } ?? "U")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(colors.primary)
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Profile Info Cards
            HStack(spacing: 12) {
                ModernProfileInfoCard(
                    title: "Member Since",
                    value: "2024",
                    icon: "calendar",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.2,
                    onTap: { showMemberSinceDetail = true }
                )
                
                ModernProfileInfoCard(
                    title: "Wellness Score",
                    value: "85%",
                    icon: "heart.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3,
                    onTap: { showWellnessScoreDetail = true }
                )
                
                ModernProfileInfoCard(
                    title: "Achievements",
                    value: "12",
                    icon: "trophy.fill",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4,
                    onTap: { showAchievementsDetail = true }
                )
            }
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Wellness Quote Card
    var indianWellnessQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Spacer()
                
                Text("Wellness Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Text(indianWellnessQuotes.randomElement() ?? indianWellnessQuotes[0])
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
    
    // MARK: - Profile Stats Overview
    var profileStatsOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Wellness Stats")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ModernProfileStatCard(
                    title: "Current Weight",
                    value: "\(viewModel.profileData.weight ?? 0) kg",
                    icon: "scalemass.fill",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.5
                )
                
                ModernProfileStatCard(
                    title: "Height",
                    value: "\(viewModel.profileData.height ?? 0) cm",
                    icon: "ruler.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.6
                )
                
                ModernProfileStatCard(
                    title: "Activity Level",
                    value: viewModel.profileData.activityLevel ?? "Not Set",
                    icon: "figure.run",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.7
                )
                
                ModernProfileStatCard(
                    title: "Fitness Goal",
                    value: viewModel.profileData.weightLossStrategy ?? "Not Set",
                    icon: "target",
                    color: .purple,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.8
                )
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Personal Information Section
    var personalInformationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Personal Information")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button("Edit") {
                    // Edit personal info
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            LazyVStack(spacing: 12) {
                ModernProfileDetailCard(
                    title: "Full Name",
                    value: "\(viewModel.profileData.firstName ?? "") \(viewModel.profileData.lastName ?? "")",
                    icon: "person.fill",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.9
                )
                
                ModernProfileDetailCard(
                    title: "Email",
                    value: viewModel.profileData.email ?? "Not Set",
                    icon: "envelope.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.0
                )
                
                ModernProfileDetailCard(
                    title: "Date of Birth",
                    value: viewModel.profileData.dob ?? "Not Set",
                    icon: "calendar",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.1
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
    }
    
    // MARK: - Health & Wellness Section
    var healthWellnessSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Health & Wellness")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(healthWellnessItems, id: \.self) { item in
                        HealthWellnessCard(
                            title: item.title,
                            value: item.value,
                            icon: item.icon,
                            color: item.color,
                            theme: colors,
                            animateContent: $animateContent,
                            delay: 1.2 + Double(healthWellnessItems.firstIndex(of: item) ?? 0) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateContent)
    }
    
    // MARK: - Achievements & Goals Section
    var achievementsGoalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements & Goals")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                            .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button("View All") {
                    // Show all achievements
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            // Weight Loss Progress Card
            if let weightLost = viewModel.weightLost, weightLost > 0, let goal = viewModel.profileData.weightLossGoal, goal > 0 {
                WeightLossProgressCard(
                    weightLost: weightLost,
                    goal: goal,
                    progress: viewModel.weightLossProgress,
                    motivationalMessage: viewModel.motivationalMessage,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.3
                )
            }
            
            LazyVStack(spacing: 12) {
                ForEach(achievementsList, id: \.self) { achievement in
                    ProfileAchievementCard(
                        title: achievement.title,
                        description: achievement.description,
                        icon: achievement.icon,
                        color: achievement.color,
                        theme: colors,
                        animateContent: $animateContent,
                        delay: 1.4 + Double(achievementsList.firstIndex(of: achievement) ?? 0) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.3), value: animateContent)
    }
    
    // MARK: - Connected Services Section
    var connectedServicesSection: some View {
        VStack(spacing: 16) {
                        HStack {
                Text("Connected Services")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                
                            Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ConnectedServiceCard(
                    title: "Strava",
                    description: "Connect your fitness activities",
                    icon: "figure.run",
                    isConnected: stravaAuthViewModel.isStravaConnected,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.4
                )
                
                ConnectedServiceCard(
                    title: "Apple Health",
                    description: "Sync your health data",
                    icon: "heart.fill",
                    isConnected: viewModel.profileData.steps != nil || viewModel.profileData.caloriesBurned != nil,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.5
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.4), value: animateContent)
    }
    
    // MARK: - Settings & Preferences Section
    var settingsPreferencesSection: some View {
        VStack(spacing: 16) {
                        HStack {
                Text("Settings & Preferences")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                
                            Spacer()
                            
                            Button("Manage") {
                                showSettingsView = true
                            }
                            .font(FitGlideTheme.bodySmall)
                            .foregroundColor(colors.primary)
                        }
            
            LazyVStack(spacing: 12) {
                ForEach(settingsItems, id: \.self) { item in
                    SettingsCard(
                        title: item.title,
                        description: item.description,
                        icon: item.icon,
                        color: item.color,
                        theme: colors,
                        animateContent: $animateContent,
                        delay: 1.6 + Double(settingsItems.firstIndex(of: item) ?? 0) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.6), value: animateContent)
    }
    
    // MARK: - Account Actions Section
    var accountActionsSection: some View {
        VStack(spacing: 16) {
                        HStack {
                Text("Account Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                            Spacer()
            }
            
            VStack(spacing: 12) {
                ModernProfileActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .blue,
                    action: { /* Export data */ },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.7
                )
                
                ModernProfileActionButton(
                    title: "Delete Account",
                    icon: "trash.fill",
                    color: .red,
                    action: { showDeleteAccountConfirmation = true },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.8
                )
                
                ModernProfileActionButton(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: .orange,
                    action: { authRepository.logout() },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.9
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.7), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var indianWellnessQuotes: [String] {
        [
            "Your body is your temple, treat it with respect and care.",
            "Every step towards wellness is a step towards happiness.",
            "Health is the greatest gift, contentment the greatest wealth.",
            "Your wellness journey is unique, embrace it with joy.",
            "Small daily improvements are the key to lasting change."
        ]
    }
    
    private var healthWellnessItems: [HealthWellnessItem] {
        [
            HealthWellnessItem(
                title: "BMI", 
                value: viewModel.profileData.bmi.map { String(format: "%.1f", $0) } ?? "N/A", 
                icon: "chart.bar.fill", 
                color: .blue
            ),
            HealthWellnessItem(
                title: "BMR", 
                value: viewModel.profileData.bmr.map { "\(Int($0)) kcal" } ?? "N/A", 
                icon: "flame.fill", 
                color: .orange
            ),
            HealthWellnessItem(
                title: "TDEE", 
                value: viewModel.profileData.tdee.map { "\(Int($0)) kcal" } ?? "N/A", 
                icon: "chart.line.uptrend.xyaxis", 
                color: .green
            ),
            HealthWellnessItem(
                title: "Steps Today", 
                value: viewModel.profileData.steps.map { "\($0)" } ?? "0", 
                icon: "figure.walk", 
                color: .purple
            )
        ]
    }
    
    private var achievementsList: [ProfileAchievement] {
        var achievements: [ProfileAchievement] = []
        
        // Profile completion achievement
        if areHealthVitalsValid {
            achievements.append(ProfileAchievement(
                title: "Profile Complete", 
                description: "Completed your health profile setup", 
                icon: "checkmark.circle.fill", 
                color: .green
            ))
        }
        
        // Weight loss progress achievement
        if let weightLost = viewModel.weightLost, weightLost > 0 {
            achievements.append(ProfileAchievement(
                title: "Weight Loss Progress", 
                description: "Lost \(String(format: "%.1f", weightLost)) kg so far", 
                icon: "arrow.down.circle.fill", 
                color: .blue
            ))
        }
        
        // Goal setting achievement
        if areGoalsValid {
            achievements.append(ProfileAchievement(
                title: "Goal Setter", 
                description: "Set your fitness and wellness goals", 
                icon: "target", 
                color: .orange
            ))
        }
        
        // Today's steps achievement
        if let steps = viewModel.profileData.steps, steps > 0 {
            let stepGoal = viewModel.profileData.stepGoal ?? 10000
            let progress = min(steps / Float(stepGoal), 1.0)
            if progress >= 0.5 {
                achievements.append(ProfileAchievement(
                    title: "Step Progress", 
                    description: "\(Int(steps)) steps today (\(Int(progress * 100))% of goal)", 
                    icon: "figure.walk", 
                    color: .purple
                ))
            }
        }
        
        // If no achievements, show a motivational one
        if achievements.isEmpty {
            achievements.append(ProfileAchievement(
                title: "Getting Started", 
                description: "Begin your wellness journey today", 
                icon: "star.fill", 
                color: .yellow
            ))
        }
        
        return achievements
    }
    
    private var settingsItems: [SettingsItem] {
        [
            SettingsItem(
                title: "Notifications", 
                description: viewModel.profileData.notificationsEnabled ? "Enabled" : "Disabled", 
                icon: "bell.fill", 
                color: viewModel.profileData.notificationsEnabled ? .green : .red
            ),
            SettingsItem(
                title: "Max Greetings", 
                description: viewModel.profileData.maxGreetingsEnabled ? "Enabled" : "Disabled", 
                icon: "hand.wave.fill", 
                color: viewModel.profileData.maxGreetingsEnabled ? .green : .red
            ),
            SettingsItem(
                title: "Step Goal", 
                description: "\(viewModel.profileData.stepGoal ?? 10000) steps/day", 
                icon: "figure.walk", 
                color: .blue
            ),
            SettingsItem(
                title: "Water Goal", 
                description: "\(Int(viewModel.profileData.waterGoal ?? 2.5))L/day", 
                icon: "drop.fill", 
                color: .cyan
            )
        ]
    }
    
    // MARK: - Account Deletion
    
    private func performAccountDeletion() async {
        isDeletingAccount = true
        
        let result = await authRepository.deleteAccount()
        
        await MainActor.run {
            isDeletingAccount = false
            deleteAccountMessage = result.message
            showDeleteAccountAlert = true
        }
    }
}

// MARK: - Account Deletion Confirmation View

struct DeleteAccountConfirmationView: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showFinalConfirmation = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Warning Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top, 40)
                
                // Title
                Text("Delete Account")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                // Warning Message
                VStack(spacing: 16) {
                    Text("This action cannot be undone!")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("Deleting your account will permanently remove:")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        DeletionItem(icon: "heart.fill", text: "All health data and vitals")
                        DeletionItem(icon: "bed.double.fill", text: "Sleep tracking history")
                        DeletionItem(icon: "figure.run", text: "Workout logs and plans")
                        DeletionItem(icon: "fork.knife", text: "Meal and nutrition data")
                        DeletionItem(icon: "person.2.fill", text: "Social connections and challenges")
                        DeletionItem(icon: "chart.bar.fill", text: "Progress and achievements")
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showFinalConfirmation = true
                    }) {
                        Text("Delete My Account")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.medium)
                            .foregroundColor(colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(colors.background.ignoresSafeArea())
        }
        .alert("Final Confirmation", isPresented: $showFinalConfirmation) {
            Button("Delete Forever", role: .destructive) {
                onConfirm()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you absolutely sure? This will permanently delete your account and all associated data.")
        }
    }
}

struct DeletionItem: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 24)
            
            Text(text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurface)
            
            Spacer()
        }
    }
}

// MARK: - Weight Loss Progress Card

struct WeightLossProgressCard: View {
    let weightLost: Double
    let goal: Double
    let progress: Float
    let motivationalMessage: String
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight Loss Progress")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text(motivationalMessage)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(String(format: "%.1f", weightLost)) kg lost")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", goal)) kg goal")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.surfaceVariant)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                            .animation(.easeInOut(duration: 1.0), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

// MARK: - Modern Profile Components
struct ModernProfileInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text(value)
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ModernProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(value)
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            }
            .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ModernProfileDetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct HealthWellnessCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
            HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
            }
            
                Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ProfileAchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ConnectedServiceCard: View {
    let title: String
    let description: String
    let icon: String
    let isConnected: Bool
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isConnected ? .green : theme.onSurfaceVariant)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
            }
            
                        Spacer()
            
            Image(systemName: isConnected ? "checkmark.circle.fill" : "plus.circle")
                .foregroundColor(isConnected ? .green : theme.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct SettingsCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ModernProfileActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

    var body: some View {
        Button(action: action) {
        HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
                
            Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}



// MARK: - IdentifiableString
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

// MARK: - Supporting Data Structures
struct HealthWellnessItem: Hashable {
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct ProfileAchievement: Hashable {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct SettingsItem: Hashable {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Detail Views
struct MemberSinceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Member Since")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text("You joined FitGlide in 2024")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.onSurfaceVariant)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Member Since")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}

struct WellnessScoreDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Wellness Score")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text("Your current wellness score is 85%")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.onSurfaceVariant)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Wellness Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}

struct AchievementsDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Achievements")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text("You have earned 12 achievements")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.onSurfaceVariant)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}

struct StressLevelDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Stress Level")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text("Your current stress level is moderate")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.onSurfaceVariant)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Stress Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let authRepo = AuthRepository()
    let strapiRepo = StrapiRepository(authRepository: authRepo)
    let profileVM = ProfileViewModel(strapiRepository: strapiRepo, authRepository: authRepo, healthService: HealthService())
    let stravaAuthVM = StravaAuthViewModel(authRepository: authRepo)
    let navigationVM = NavigationViewModel()
    ProfileView(
        viewModel: profileVM,
        stravaAuthViewModel: stravaAuthVM,
        navigationViewModel: navigationVM,
        authRepository: authRepo
    )
}
