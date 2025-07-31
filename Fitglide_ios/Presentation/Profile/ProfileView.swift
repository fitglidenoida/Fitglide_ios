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
                    delay: 0.2
                )
                
                ModernProfileInfoCard(
                    title: "Wellness Score",
                    value: "85%",
                    icon: "heart.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                ModernProfileInfoCard(
                    title: "Achievements",
                    value: "12",
                    icon: "trophy.fill",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4
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
            
            LazyVStack(spacing: 12) {
                ForEach(achievementsList, id: \.self) { achievement in
                    ProfileAchievementCard(
                        title: achievement.title,
                        description: achievement.description,
                        icon: achievement.icon,
                        color: achievement.color,
                        theme: colors,
                        animateContent: $animateContent,
                        delay: 1.3 + Double(achievementsList.firstIndex(of: achievement) ?? 0) * 0.1
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
                    isConnected: false,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.4
                )
                
                ConnectedServiceCard(
                    title: "Apple Health",
                    description: "Sync your health data",
                    icon: "heart.fill",
                    isConnected: true,
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
                    action: { /* Delete account */ },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 1.8
                )
                
                ModernProfileActionButton(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    color: .orange,
                    action: { /* Sign out */ },
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
            HealthWellnessItem(title: "BMI", value: "22.5", icon: "chart.bar.fill", color: .blue),
            HealthWellnessItem(title: "BMR", value: "1,650 kcal", icon: "flame.fill", color: .orange),
            HealthWellnessItem(title: "TDEE", value: "2,100 kcal", icon: "chart.line.uptrend.xyaxis", color: .green),
            HealthWellnessItem(title: "Body Fat", value: "18%", icon: "percent", color: .purple)
        ]
    }
    
    private var achievementsList: [ProfileAchievement] {
        [
            ProfileAchievement(title: "First Week Complete", description: "Completed your first week of tracking", icon: "star.fill", color: .yellow),
            ProfileAchievement(title: "Step Master", description: "Achieved 10,000 steps for 7 days", icon: "figure.walk", color: .green),
            ProfileAchievement(title: "Wellness Warrior", description: "Maintained consistent sleep for 30 days", icon: "moon.stars.fill", color: .purple)
        ]
    }
    
    private var settingsItems: [SettingsItem] {
        [
            SettingsItem(title: "Notifications", description: "Manage your notification preferences", icon: "bell.fill", color: .blue),
            SettingsItem(title: "Privacy", description: "Control your data privacy settings", icon: "lock.fill", color: .green),
            SettingsItem(title: "Units", description: "Choose your preferred units", icon: "ruler", color: .orange),
            SettingsItem(title: "Language", description: "Select your preferred language", icon: "globe", color: .purple)
        ]
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
