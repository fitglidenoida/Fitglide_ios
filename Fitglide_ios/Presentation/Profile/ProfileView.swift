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

    // Edit state
    @State private var showWeightEdit = false
    @State private var showHeightEdit = false
    @State private var showActivityLevelEdit = false
    @State private var showSmartGoalEdit = false
    @State private var showWellnessStatsEdit = false
    @State private var showPersonalInfoEdit = false
    @State private var showStravaAuth = false
    @State private var showAppleHealthPermissions = false
    @State private var showExportData = false

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
        viewModel.profileData.lifeGoalCategory != nil &&
        viewModel.profileData.lifeGoalType != nil &&
        viewModel.profileData.goalTimeline != nil &&
        viewModel.profileData.goalCommitmentLevel != nil
    }
    
    private func getSmartGoalDisplayValue() -> String {
        if let category = viewModel.profileData.lifeGoalCategory,
           let type = viewModel.profileData.lifeGoalType {
            let shortCategory = String(category.prefix(10))
            let shortType = String(type.prefix(15))
            if let timeline = viewModel.profileData.goalTimeline {
                return "\(shortCategory) - \(shortType) (\(timeline)M)"
            } else {
                return "\(shortCategory) - \(shortType)"
            }
        }
        
        return "Not Set"
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
                        
                        // Smart Goals Section
                        smartGoalsSection
                        
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
                        
                        // Legal Section
                        legalSection
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
                MemberSinceDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $showWellnessScoreDetail) {
                WellnessScoreDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAchievementsDetail) {
                AchievementsDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $showStressLevelDetail) {
                StressLevelDetailView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showWeightEdit) {
                WeightEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHeightEdit) {
                HeightEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showActivityLevelEdit) {
                ActivityLevelEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSmartGoalEdit) {
                SmartGoalEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showWellnessStatsEdit) {
                WellnessStatsEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showPersonalInfoEdit) {
                PersonalInfoEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showStravaAuth) {
                StravaAuthView(viewModel: stravaAuthViewModel)
            }
            .sheet(isPresented: $showAppleHealthPermissions) {
                HealthPermissionsView()
            }
            .sheet(isPresented: $showExportData) {
                ExportDataView(viewModel: viewModel)
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
                set: { _ in 
                    DispatchQueue.main.async {
                        viewModel.uiMessage = nil
                    }
                }
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
                    value: viewModel.memberSinceYear,
                    icon: "calendar",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.2,
                    onTap: { showMemberSinceDetail = true }
                )
                
                ModernProfileInfoCard(
                    title: "Wellness Score",
                    value: viewModel.wellnessScore,
                    icon: "heart.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3,
                    onTap: { showWellnessScoreDetail = true }
                )
                
                ModernProfileInfoCard(
                    title: "Achievements",
                    value: viewModel.achievementsCount,
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
                
                Button("Edit") {
                    showWellnessStatsEdit = true
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            // Top row: Height and Weight cards (equal size)
            HStack(spacing: 12) {
                ModernProfileStatCard(
                    title: "Current Weight",
                    value: "\(viewModel.profileData.weight ?? 0) kg",
                    icon: "scalemass.fill",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.5
                )
                .onTapGesture {
                    showWeightEdit = true
                }
                
                ModernProfileStatCard(
                    title: "Height",
                    value: "\(viewModel.profileData.height ?? 0) cm",
                    icon: "ruler.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.6
                )
                .onTapGesture {
                    showHeightEdit = true
                }
            }
            
            // Bottom row: Activity Level card (full width)
            ModernProfileStatCard(
                title: "Activity Level",
                value: viewModel.profileData.activityLevel ?? "Not Set",
                icon: "figure.run",
                color: .orange,
                theme: colors,
                animateContent: $animateContent,
                delay: 0.7
            )
            .onTapGesture {
                showActivityLevelEdit = true
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
    
    // MARK: - Smart Goals Section
    var smartGoalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Smart Goals")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button("Edit") {
                    showSmartGoalEdit = true
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.primary)
            }
            
            // Simple icon display like other wellness stat cards
            VStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 32))
                    .foregroundColor(colors.onSurfaceVariant)
                
                if let categoryString = viewModel.profileData.lifeGoalCategory,
                   let _ = LifeGoalCategory(rawValue: categoryString) {
                    Text("Goals Set")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.primary)
                        .fontWeight(.medium)
                } else {
                    Text("No Goals Set")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showSmartGoalEdit) {
            SmartGoalEditView(viewModel: viewModel)
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
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
                    showPersonalInfoEdit = true
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
            
            LazyVStack(spacing: 12) {
                
                // Regular Achievements
                ForEach(achievementsList, id: \.self) { achievement in
                    ProfileAchievementCard(
                        title: achievement.title,
                        description: achievement.description,
                        icon: achievement.icon,
                        color: achievement.color,
                        theme: colors,
                        animateContent: $animateContent,
                        delay: 1.5 + Double(achievementsList.firstIndex(of: achievement) ?? 0) * 0.1
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
                    delay: 1.4,
                    onTap: {
                        showStravaAuth = true
                    }
                )
                
                ConnectedServiceCard(
                    title: "Apple Health",
                    description: "Sync your health data",
                    icon: "heart.fill",
                    isConnected: viewModel.profileData.steps != nil || viewModel.profileData.caloriesBurned != nil,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.5,
                    onTap: {
                        showAppleHealthPermissions = true
                    }
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
                            .font(FitGlideTheme.bodyMedium)
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
                    action: { showExportData = true },
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
    
    // MARK: - Legal Section
    var legalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Legal")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernProfileActionButton(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    color: .blue,
                    action: {
                        if let url = URL(string: "https://fitglide.in/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.9
                )
                
                ModernProfileActionButton(
                    title: "Terms & Conditions",
                    icon: "doc.text.fill",
                    color: .green,
                    action: {
                        if let url = URL(string: "https://fitglide.in/terms-conditions.html") {
                            UIApplication.shared.open(url)
                        }
                    },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 2.0
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.9), value: animateContent)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
        }
        .buttonStyle(PlainButtonStyle())
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
    @ObservedObject var viewModel: ProfileViewModel
    
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
                
                Text("You joined FitGlide in \(viewModel.memberSinceYear)")
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
    @ObservedObject var viewModel: ProfileViewModel
    
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
                
                Text("Your current wellness score is \(viewModel.wellnessScore)")
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
    @ObservedObject var viewModel: ProfileViewModel
    
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
                
                Text("You have earned \(viewModel.achievementsCount) achievements")
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
    @ObservedObject var viewModel: ProfileViewModel
    
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
                
                Text("Your current stress level is \(calculateStressLevel())")
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
    
    private func calculateStressLevel() -> String {
        // Calculate stress level based on sleep quality, heart rate, and activity
        let sleepQuality = 0.85 // This should come from real data
        let heartRateHealth = 0.9 // This should come from real data
        let activityLevel = 0.8 // This should come from real data
        
        let stressScore = (sleepQuality + heartRateHealth + activityLevel) / 3.0
        
        if stressScore >= 0.8 {
            return "Low"
        } else if stressScore >= 0.6 {
            return "Moderate"
        } else {
            return "High"
        }
    }
}

// MARK: - Edit Views
struct WeightEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var weight: String = ""
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Weight")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                TextField("Enter weight in kg", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .padding()
                
                Button("Save") {
                    if let weightValue = Double(weight) {
                        Task {
                            await viewModel.updateWeight(weightValue)
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(weight.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
            .onAppear {
                weight = String(viewModel.profileData.weight ?? 0)
            }
        }
    }
}

struct HeightEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var height: String = ""
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Height")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                TextField("Enter height in cm", text: $height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                
                Button("Save") {
                    if let heightValue = Double(height) {
                        Task {
                            await viewModel.updateHeight(heightValue)
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(height.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
            .onAppear {
                height = String(viewModel.profileData.height ?? 0)
            }
        }
    }
}

struct ActivityLevelEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedActivityLevel: String = ""
    
    private let activityLevels = [
        "Sedentary (little/no exercise)",
        "Light exercise (1-3 days/week)",
        "Moderate exercise (3-5 days/week)",
        "Heavy exercise (6-7 days/week)",
        "Very heavy exercise (Twice/day)"
    ]
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Activity Level")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Picker("Activity Level", selection: $selectedActivityLevel) {
                    ForEach(activityLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Button("Save") {
                    Task {
                        await viewModel.updateActivityLevel(selectedActivityLevel)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedActivityLevel.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Activity Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
            .onAppear {
                selectedActivityLevel = viewModel.profileData.activityLevel ?? ""
            }
        }
    }
}



struct WellnessStatsEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var currentWeight: String = ""
    @State private var currentHeight: String = ""
    @State private var selectedActivityLevel: String = ""
    @State private var animateContent = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extremely Active"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: FitGlideTheme.Spacing.large) {
                        // Modern Header Section
                        modernHeaderSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        
                        // Weight Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "scalemass.fill")
                                        .font(.title2)
                                        .foregroundColor(colors.primary)
                                    
                                    Text("Current Weight")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    TextField("Enter weight", text: $currentWeight)
                                        .font(FitGlideTheme.bodyLarge)
                                        .padding(FitGlideTheme.Spacing.medium)
                                        .background(
                                            RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                                .fill(colors.surfaceVariant)
                                        )
                                        .keyboardType(.decimalPad)
                                    
                                    Text("kg")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.onSurfaceVariant)
                                        .frame(width: 40)
                                }
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        
                        // Height Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "ruler.fill")
                                        .font(.title2)
                                        .foregroundColor(colors.quaternary)
                                    
                                    Text("Current Height")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    TextField("Enter height", text: $currentHeight)
                                        .font(FitGlideTheme.bodyLarge)
                                        .padding(FitGlideTheme.Spacing.medium)
                                        .background(
                                            RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                                .fill(colors.surfaceVariant)
                                        )
                                        .keyboardType(.decimalPad)
                                    
                                    Text("cm")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.onSurfaceVariant)
                                        .frame(width: 40)
                                }
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                        
                        // Activity Level Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "figure.run")
                                        .font(.title2)
                                        .foregroundColor(colors.tertiary)
                                    
                                    Text("Activity Level")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                Menu {
                                    ForEach(activityLevels, id: \.self) { level in
                                        Button(level) {
                                            selectedActivityLevel = level
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedActivityLevel.isEmpty ? "Select Activity Level" : selectedActivityLevel)
                                            .font(FitGlideTheme.bodyLarge)
                                            .foregroundColor(selectedActivityLevel.isEmpty ? colors.onSurfaceVariant : colors.onSurface)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(colors.onSurfaceVariant)
                                    }
                                    .padding(FitGlideTheme.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                            .fill(colors.surfaceVariant)
                                    )
                                }
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                        
                        // Action Buttons
                        VStack(spacing: FitGlideTheme.Spacing.medium) {
                            ModernButton(
                                title: "Save Changes",
                                icon: "checkmark.circle.fill",
                                style: .primary
                            ) {
                                Task {
                                    await saveWellnessStats()
                                }
                            }
                            .disabled(currentWeight.isEmpty || currentHeight.isEmpty || selectedActivityLevel.isEmpty)
                            
                            ModernButton(
                                title: "Cancel",
                                icon: "xmark.circle.fill",
                                style: .tertiary
                            ) {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, FitGlideTheme.Spacing.large)
                        .padding(.bottom, FitGlideTheme.Spacing.extraLarge)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
                    }
                    .padding(.horizontal, FitGlideTheme.Spacing.large)
                    .padding(.top, FitGlideTheme.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.medium) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
                .padding(.top, FitGlideTheme.Spacing.large)
            
            VStack(spacing: FitGlideTheme.Spacing.small) {
                Text("Edit Wellness Stats")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("Update your health information to get personalized insights")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, FitGlideTheme.Spacing.large)
    }
    
    private func loadCurrentValues() {
        if let weight = viewModel.profileData.weight {
            currentWeight = String(format: "%.1f", weight)
        }
        if let height = viewModel.profileData.height {
            currentHeight = String(format: "%.1f", height)
        }
        selectedActivityLevel = viewModel.profileData.activityLevel ?? ""
    }
    
    private func saveWellnessStats() async {
        // Update weight
        if let weight = Double(currentWeight) {
            await viewModel.updateWeight(weight)
        }
        
        // Update height
        if let height = Double(currentHeight) {
            await viewModel.updateHeight(height)
        }
        
        // Update activity level
        if !selectedActivityLevel.isEmpty {
            await viewModel.updateActivityLevel(selectedActivityLevel)
        }
        
        dismiss()
    }
}

// MARK: - Smart Goals Card
struct SmartGoalsCard: View {
    let viewModel: ProfileViewModel
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    @State private var showSmartGoalEdit = false
    
    private func getColorForCategory(_ category: LifeGoalCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "pink": return .pink
        case "green": return .green
        case "purple": return .purple
        case "blue": return .blue
        default: return .blue
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Goals")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("AI-powered smart goals")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Button("Edit") {
                    showSmartGoalEdit = true
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.primary)
            }
            
            // Simple icon display like other wellness stat cards
            VStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 32))
                    .foregroundColor(theme.onSurfaceVariant)
                
                if let categoryString = viewModel.profileData.lifeGoalCategory,
                   let _ = LifeGoalCategory(rawValue: categoryString) {
                    Text("Goals Set")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.primary)
                        .fontWeight(.medium)
                } else {
                    Text("No Goals Set")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showSmartGoalEdit) {
            SmartGoalEditView(viewModel: viewModel)
        }
    }
}

// MARK: - Smart Goal Edit View
struct SmartGoalEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempCategory: LifeGoalCategory?
    @State private var tempType: LifeGoalType?
    @State private var tempTimeline: GoalTimeline?
    @State private var tempCommitment: GoalCommitmentLevel?
    
    private func getColorForCategory(_ category: LifeGoalCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "pink": return .pink
        case "green": return .green
        case "purple": return .purple
        case "blue": return .blue
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Goal Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's your main wellness focus?")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(LifeGoalCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        tempCategory = category
                                        tempType = nil
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(tempCategory == category ? .white : getColorForCategory(category))
                                            
                                            Text(category.rawValue)
                                                .font(FitGlideTheme.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(tempCategory == category ? .white : .primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(tempCategory == category ? getColorForCategory(category) : Color.gray.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Goal Type Selection (only show if category is selected)
                        if let category = tempCategory {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What specific goal do you want to achieve?")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(LifeGoalType.allCases.filter { $0.category == category }, id: \.self) { type in
                                        Button(action: {
                                            tempType = type
                                        }) {
                                            HStack {
                                                Text(type.rawValue)
                                                    .font(FitGlideTheme.bodyMedium)
                                                    .foregroundColor(tempType == type ? .white : .primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                                
                                                if tempType == type {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(tempType == type ? getColorForCategory(category) : Color.gray.opacity(0.1))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Timeline Selection (only show if type is selected)
                        if tempType != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How long do you want to work on this goal?")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(GoalTimeline.allCases, id: \.self) { timeline in
                                        Button(action: {
                                            tempTimeline = timeline
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("\(timeline.rawValue) months")
                                                        .font(FitGlideTheme.bodyMedium)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(tempTimeline == timeline ? .white : .primary)
                                                    
                                                    Text(timeline.description)
                                                        .font(FitGlideTheme.caption)
                                                        .foregroundColor(tempTimeline == timeline ? .white.opacity(0.8) : .secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                if tempTimeline == timeline {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(tempTimeline == timeline ? Color.blue : Color.gray.opacity(0.1))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Commitment Level Selection (only show if timeline is selected)
                        if tempTimeline != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How committed are you to this goal?")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(GoalCommitmentLevel.allCases, id: \.self) { commitment in
                                        Button(action: {
                                            tempCommitment = commitment
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(commitment.rawValue)
                                                        .font(FitGlideTheme.bodyMedium)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(tempCommitment == commitment ? .white : .primary)
                                                    
                                                    Text(commitment.description)
                                                        .font(FitGlideTheme.caption)
                                                        .foregroundColor(tempCommitment == commitment ? .white.opacity(0.8) : .secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                if tempCommitment == commitment {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(tempCommitment == commitment ? Color.blue : Color.gray.opacity(0.1))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Save Button
                if tempCategory != nil && tempType != nil && tempTimeline != nil && tempCommitment != nil {
                    Button("Create Smart Goal") {
                        Task {
                            await saveSmartGoal()
                        }
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Set Smart Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let categoryString = viewModel.profileData.lifeGoalCategory {
                    tempCategory = LifeGoalCategory(rawValue: categoryString)
                }
                if let typeString = viewModel.profileData.lifeGoalType {
                    tempType = LifeGoalType(rawValue: typeString)
                }
                if let timelineInt = viewModel.profileData.goalTimeline {
                    tempTimeline = GoalTimeline(rawValue: timelineInt)
                }
                if let commitmentString = viewModel.profileData.goalCommitmentLevel {
                    tempCommitment = GoalCommitmentLevel(rawValue: commitmentString)
                }
            }
        }
    }
    
    private func saveSmartGoal() async {
        guard let category = tempCategory,
              let type = tempType,
              let timeline = tempTimeline,
              let commitment = tempCommitment else { return }
        
        await viewModel.updateSmartGoals(
            category: category,
            type: type,
            timeline: timeline,
            commitment: commitment
        )
        
        dismiss()
    }
}

// MARK: - Personal Info Edit View
struct PersonalInfoEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var tempFirstName: String = ""
    @State private var tempLastName: String = ""
    @State private var tempEmail: String = ""
    @State private var tempDOB: String = ""
    @State private var animateContent = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: FitGlideTheme.Spacing.large) {
                        // Modern Header Section
                        modernHeaderSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                        
                        // First Name Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .font(.title2)
                                        .foregroundColor(colors.primary)
                                    
                                    Text("First Name")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                TextField("Enter first name", text: $tempFirstName)
                                    .font(FitGlideTheme.bodyLarge)
                                    .padding(FitGlideTheme.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                            .fill(colors.surfaceVariant)
                                    )
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        
                        // Last Name Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(colors.quaternary)
                                    
                                    Text("Last Name")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                TextField("Enter last name", text: $tempLastName)
                                    .font(FitGlideTheme.bodyLarge)
                                    .padding(FitGlideTheme.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                            .fill(colors.surfaceVariant)
                                    )
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                        
                        // Email Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.title2)
                                        .foregroundColor(colors.tertiary)
                                    
                                    Text("Email Address")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                TextField("Enter email address", text: $tempEmail)
                                    .font(FitGlideTheme.bodyLarge)
                                    .padding(FitGlideTheme.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                            .fill(colors.surfaceVariant)
                                    )
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                        
                        // Date of Birth Section
                        ModernCard(
                            padding: FitGlideTheme.Spacing.large,
                            backgroundColor: colors.surface
                        ) {
                            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                        .foregroundColor(colors.secondary)
                                    
                                    Text("Date of Birth")
                                        .font(FitGlideTheme.titleMedium)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colors.onSurface)
                                    
                                    Spacer()
                                }
                                
                                TextField("YYYY-MM-DD", text: $tempDOB)
                                    .font(FitGlideTheme.bodyLarge)
                                    .padding(FitGlideTheme.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.smallCornerRadius)
                                            .fill(colors.surfaceVariant)
                                    )
                                    .keyboardType(.numbersAndPunctuation)
                            }
                        }
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
                        
                        // Action Buttons
                        VStack(spacing: FitGlideTheme.Spacing.medium) {
                            ModernButton(
                                title: "Save Changes",
                                icon: "checkmark.circle.fill",
                                style: .primary
                            ) {
                                Task {
                                    await savePersonalInfo()
                                }
                            }
                            .disabled(tempFirstName.isEmpty && tempLastName.isEmpty && tempEmail.isEmpty && tempDOB.isEmpty)
                            
                            ModernButton(
                                title: "Cancel",
                                icon: "xmark.circle.fill",
                                style: .tertiary
                            ) {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, FitGlideTheme.Spacing.large)
                        .padding(.bottom, FitGlideTheme.Spacing.extraLarge)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
                    }
                    .padding(.horizontal, FitGlideTheme.Spacing.large)
                    .padding(.top, FitGlideTheme.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.medium) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
                .padding(.top, FitGlideTheme.Spacing.large)
            
            VStack(spacing: FitGlideTheme.Spacing.small) {
                Text("Edit Personal Information")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("Update your personal details to personalize your experience")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, FitGlideTheme.Spacing.large)
    }
    
    private func loadCurrentValues() {
        tempFirstName = viewModel.profileData.firstName ?? ""
        tempLastName = viewModel.profileData.lastName ?? ""
        tempEmail = viewModel.profileData.email ?? ""
        tempDOB = viewModel.profileData.dob ?? ""
    }
    
    private func savePersonalInfo() async {
        await viewModel.updatePersonalInfo(
            firstName: tempFirstName.isEmpty ? nil : tempFirstName,
            lastName: tempLastName.isEmpty ? nil : tempLastName,
            email: tempEmail.isEmpty ? nil : tempEmail,
            dob: tempDOB.isEmpty ? nil : tempDOB
        )
        
        dismiss()
    }
}

// MARK: - Strava Auth View
struct StravaAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: StravaAuthViewModel
    
    @State private var animateContent = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: FitGlideTheme.Spacing.large) {
                        if viewModel.isLoading {
                            // Show loading state while authenticating
                            loadingSection
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        } else if let errorMessage = viewModel.errorMessage {
                            // Show error if authentication failed
                            errorMessageCard(errorMessage)
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        } else if viewModel.isStravaConnected {
                            // Show success state if connected
                            successSection
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        } else {
                            // Show initial state (shouldn't happen with auto-auth, but just in case)
                            initialSection
                                .offset(y: animateContent ? 0 : 20)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                        }
                    }
                    .padding(.horizontal, FitGlideTheme.Spacing.large)
                    .padding(.top, FitGlideTheme.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
                
                // Automatically initiate Strava auth if not already connected
                if !viewModel.isStravaConnected {
                    viewModel.initiateStravaAuth()
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.medium) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
                .padding(.top, FitGlideTheme.Spacing.large)
            
            VStack(spacing: FitGlideTheme.Spacing.small) {
                Text("Strava Connection")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("Connect your Strava account to sync your fitness activities")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, FitGlideTheme.Spacing.large)
    }
    
    // MARK: - Connection Status Card
    private var connectionStatusCard: some View {
        ModernCard(
            padding: FitGlideTheme.Spacing.large,
            backgroundColor: colors.surface
        ) {
            VStack(spacing: FitGlideTheme.Spacing.medium) {
                HStack {
                    Image(systemName: viewModel.isStravaConnected ? "checkmark.circle.fill" : "link.circle")
                        .font(.title2)
                        .foregroundColor(viewModel.isStravaConnected ? .green : colors.primary)
                    
                    VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.small) {
                        Text(viewModel.isStravaConnected ? "Connected to Strava" : "Not Connected")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.onSurface)
                        
                        Text(viewModel.isStravaConnected ? "Your fitness activities are being synced" : "Connect to start syncing your activities")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.medium) {
            if viewModel.isStravaConnected {
                // Disconnect Button
                ModernButton(
                    title: "Disconnect Strava",
                    icon: "link.badge.minus",
                    style: .secondary
                ) {
                    viewModel.disconnectStrava()
                }
            } else {
                // Connect Button
                ModernButton(
                    title: "Connect to Strava",
                    icon: "link.badge.plus",
                    style: .primary
                ) {
                    viewModel.initiateStravaAuth()
                }
                .disabled(viewModel.isLoading)
            }
            
            // Cancel Button
            ModernButton(
                title: "Cancel",
                icon: "xmark.circle.fill",
                style: .tertiary
            ) {
                dismiss()
            }
        }
        .padding(.horizontal, FitGlideTheme.Spacing.large)
        .padding(.bottom, FitGlideTheme.Spacing.extraLarge)
    }
    
    // MARK: - Error Message Card
    private func errorMessageCard(_ message: String) -> some View {
        ModernCard(
            padding: FitGlideTheme.Spacing.large,
            backgroundColor: Color.red.opacity(0.1)
        ) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.small) {
                    Text("Connection Error")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text(message)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurface)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.large) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: colors.primary))
            
            Text("Connecting to Strava...")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)
            
            Text("Please wait while we establish the connection")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Success Section
    private var successSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Successfully Connected!")
                .font(FitGlideTheme.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(colors.onSurface)
            
            Text("Your Strava account is now linked and syncing fitness data")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            ModernButton(
                title: "Done",
                icon: "checkmark.circle.fill",
                style: .primary
            ) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Initial Section
    private var initialSection: some View {
        VStack(spacing: FitGlideTheme.Spacing.large) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
            
            Text("Connect to Strava")
                .font(FitGlideTheme.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(colors.onSurface)
            
            Text("Connect your Strava account to sync your fitness activities")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            ModernButton(
                title: "Connect Now",
                icon: "link.badge.plus",
                style: .primary
            ) {
                viewModel.initiateStravaAuth()
            }
            
            ModernButton(
                title: "Cancel",
                icon: "xmark.circle.fill",
                style: .tertiary
            ) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: FitGlideTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}



// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var selectedFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var exportMessage = ""
    @State private var showExportSuccess = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .json: return "curlybraces"
            case .csv: return "tablecells"
            case .pdf: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: FitGlideTheme.Spacing.large) {
                        // Header
                        VStack(spacing: FitGlideTheme.Spacing.medium) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("Export Your Data")
                                .font(FitGlideTheme.titleLarge)
                                .fontWeight(.bold)
                                .foregroundColor(colors.onSurface)
                            
                            Text("Download your profile data, health vitals, and goals in your preferred format")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, FitGlideTheme.Spacing.large)
                        
                        // Format Selection
                        VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                            Text("Export Format")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: FitGlideTheme.Spacing.medium) {
                                ForEach(ExportFormat.allCases, id: \.self) { format in
                                    FormatSelectionCard(
                                        format: format,
                                        isSelected: selectedFormat == format,
                                        colors: colors
                                    ) {
                                        selectedFormat = format
                                    }
                                }
                            }
                        }
                        
                        // Data Preview
                        VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                            Text("Data Preview")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                            
                            DataPreviewCard(viewModel: viewModel, colors: colors)
                        }
                        
                        // Export Button
                        ModernButton(
                            title: isExporting ? "Exporting..." : "Export Data",
                            icon: isExporting ? "arrow.clockwise" : "square.and.arrow.up",
                            style: .primary
                        ) {
                            exportData()
                        }
                        .disabled(isExporting)
                        .padding(.horizontal, FitGlideTheme.Spacing.large)
                        .padding(.bottom, FitGlideTheme.Spacing.extraLarge)
                    }
                    .padding(.horizontal, FitGlideTheme.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
        }
        .alert("Export Complete", isPresented: $showExportSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(exportMessage)
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isExporting = false
            exportMessage = "Your data has been exported successfully as \(selectedFormat.rawValue) file."
            showExportSuccess = true
        }
    }
}

// MARK: - Format Selection Card
struct FormatSelectionCard: View {
    let format: ExportDataView.ExportFormat
    let isSelected: Bool
    let colors: FitGlideTheme.Colors
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: FitGlideTheme.Spacing.small) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? colors.primary : colors.onSurfaceVariant)
                
                Text(format.rawValue)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(FitGlideTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primary.opacity(0.1) : colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? colors.primary : colors.onSurfaceVariant, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Preview Card
struct DataPreviewCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    let colors: FitGlideTheme.Colors
    
    var body: some View {
        ModernCard(
            padding: FitGlideTheme.Spacing.large,
            backgroundColor: colors.surface
        ) {
            VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.medium) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                    
                    Text("What will be exported:")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: FitGlideTheme.Spacing.small) {
                    DataPreviewRow(title: "Personal Info", value: "\(viewModel.profileData.firstName ?? "N/A") \(viewModel.profileData.lastName ?? "N/A")")
                    DataPreviewRow(title: "Health Vitals", value: "Weight, Height, BMI, Activity Level")
                    DataPreviewRow(title: "Goals", value: "Life Goals, Timeline, Commitment Level")
                    DataPreviewRow(title: "Wellness Stats", value: "Steps, Calories, Sleep, Water")
                    DataPreviewRow(title: "Account Info", value: "Member since \(viewModel.memberSinceYear)")
                }
            }
        }
    }
}

// MARK: - Data Preview Row
struct DataPreviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.primary)
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
