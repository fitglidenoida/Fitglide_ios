import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var animateContent = false
    @State private var showDeleteAccountConfirmation = false
    
    // Settings state
    // @State private var themePreference: String = "system" - Removed for P2
    @State private var notificationsEnabled: Bool = true
    @State private var maxGreetingsEnabled: Bool = true
    @State private var privacySettings: [String: Bool] = [
        "profileVisible": true,
        "activityVisible": true,
        "achievementsVisible": true,
        "allowFriendRequests": true
    ]
    
    // Goal editing state
    @State private var showStepGoalEdit = false
    @State private var showWaterGoalEdit = false
    @State private var showCalorieGoalEdit = false
    @State private var showMealGoalEdit = false
    @State private var showSleepGoalEdit = false
    
    // Temporary goal values for editing
    @State private var tempStepGoal: String = ""
    @State private var tempWaterGoal: String = ""
    @State private var tempCalorieGoal: String = ""
    @State private var tempMealGoal: String = ""
    @State private var tempSleepGoal: String = ""
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header
                        modernHeaderSection
                        
                        // Appearance Settings - Removed for P2
                        // appearanceSection
                        
                        // Notification Settings
                        notificationSection
                        
                        // Privacy Settings
                        privacySection
                        
                        // Goal Management
                        goalManagementSection
                        
                        // Account Actions
                        accountActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveSettings()
                        }
                    }
                    .foregroundColor(colors.primary)
                    .fontWeight(.semibold)
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
            .onAppear {
                loadCurrentSettings()
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings ⚙️")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Customize your FitGlide experience")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Settings icon
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Appearance Section - Removed for P2
    // Theme selection will be implemented in future version
    
    // MARK: - Notification Section
    private var notificationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notifications")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Push Notifications",
                    subtitle: "Receive notifications about your progress",
                    icon: "bell.fill",
                    color: .blue,
                    isOn: $notificationsEnabled,
                    theme: colors
                )
                
                SettingsToggleRow(
                    title: "Max Greetings",
                    subtitle: "Show motivational greetings",
                    icon: "hand.wave.fill",
                    color: .green,
                    isOn: $maxGreetingsEnabled,
                    theme: colors
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Privacy")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Profile Visible",
                    subtitle: "Allow others to see your profile",
                    icon: "person.fill",
                    color: .orange,
                    isOn: Binding(
                        get: { privacySettings["profileVisible"] ?? true },
                        set: { privacySettings["profileVisible"] = $0 }
                    ),
                    theme: colors
                )
                
                SettingsToggleRow(
                    title: "Activity Visible",
                    subtitle: "Share your activity with friends",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    isOn: Binding(
                        get: { privacySettings["activityVisible"] ?? true },
                        set: { privacySettings["activityVisible"] = $0 }
                    ),
                    theme: colors
                )
                
                SettingsToggleRow(
                    title: "Achievements Visible",
                    subtitle: "Show your achievements to others",
                    icon: "trophy.fill",
                    color: .yellow,
                    isOn: Binding(
                        get: { privacySettings["achievementsVisible"] ?? true },
                        set: { privacySettings["achievementsVisible"] = $0 }
                    ),
                    theme: colors
                )
                
                SettingsToggleRow(
                    title: "Allow Friend Requests",
                    subtitle: "Let others send you friend requests",
                    icon: "person.badge.plus",
                    color: .blue,
                    isOn: Binding(
                        get: { privacySettings["allowFriendRequests"] ?? true },
                        set: { privacySettings["allowFriendRequests"] = $0 }
                    ),
                    theme: colors
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Goal Management Section
    private var goalManagementSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Goal Management")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Step Goal
                SettingsRow(
                    title: "Daily Step Goal",
                    subtitle: "Target steps per day",
                    icon: "figure.walk",
                    color: .green,
                    theme: colors
                ) {
                    HStack {
                        Text("\(viewModel.profileData.stepGoal ?? 10000)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .onTapGesture {
                    tempStepGoal = "\(viewModel.profileData.stepGoal ?? 10000)"
                    showStepGoalEdit = true
                }
                
                // Water Goal
                SettingsRow(
                    title: "Daily Water Goal",
                    subtitle: "Target water intake per day",
                    icon: "drop.fill",
                    color: .blue,
                    theme: colors
                ) {
                    HStack {
                        Text("\(viewModel.profileData.waterGoal ?? 2.5, specifier: "%.1f") L")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .onTapGesture {
                    tempWaterGoal = String(format: "%.1f", viewModel.profileData.waterGoal ?? 2.5)
                    showWaterGoalEdit = true
                }
                
                // Calorie Goal
                SettingsRow(
                    title: "Daily Calorie Goal",
                    subtitle: "Target calories per day",
                    icon: "flame.fill",
                    color: .orange,
                    theme: colors
                ) {
                    HStack {
                        Text("\(viewModel.profileData.calorieGoal ?? 2000)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .onTapGesture {
                    tempCalorieGoal = "\(viewModel.profileData.calorieGoal ?? 2000)"
                    showCalorieGoalEdit = true
                }
                
                // Meal Goal
                SettingsRow(
                    title: "Daily Meal Goal",
                    subtitle: "Target balanced meals per day",
                    icon: "fork.knife",
                    color: .purple,
                    theme: colors
                ) {
                    HStack {
                        Text("\(viewModel.profileData.mealGoal ?? 3)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .onTapGesture {
                    tempMealGoal = "\(viewModel.profileData.mealGoal ?? 3)"
                    showMealGoalEdit = true
                }
                
                // Sleep Goal
                SettingsRow(
                    title: "Daily Sleep Goal",
                    subtitle: "Target sleep hours per night",
                    icon: "bed.double.fill",
                    color: .indigo,
                    theme: colors
                ) {
                    HStack {
                        Text("\(viewModel.profileData.sleepGoal ?? 8, specifier: "%.1f") hours")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .onTapGesture {
                    tempSleepGoal = String(format: "%.1f", viewModel.profileData.sleepGoal ?? 8.0)
                    showSleepGoalEdit = true
                }
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
        .sheet(isPresented: $showStepGoalEdit) {
            GoalEditView(
                title: "Daily Step Goal",
                value: $tempStepGoal,
                unit: "steps",
                onSave: {
                    if let value = Int(tempStepGoal) {
                        Task {
                            await viewModel.updateStepGoal(value)
                        }
                    }
                    showStepGoalEdit = false
                }
            )
        }
        .sheet(isPresented: $showWaterGoalEdit) {
            GoalEditView(
                title: "Daily Water Goal",
                value: $tempWaterGoal,
                unit: "liters",
                onSave: {
                    if let value = Float(tempWaterGoal) {
                        Task {
                            await viewModel.updateWaterGoal(value)
                        }
                    }
                    showWaterGoalEdit = false
                }
            )
        }
        .sheet(isPresented: $showCalorieGoalEdit) {
            GoalEditView(
                title: "Daily Calorie Goal",
                value: $tempCalorieGoal,
                unit: "calories",
                onSave: {
                    if let value = Int(tempCalorieGoal) {
                        Task {
                            await viewModel.updateCalorieGoal(value)
                        }
                    }
                    showCalorieGoalEdit = false
                }
            )
        }
        .sheet(isPresented: $showMealGoalEdit) {
            GoalEditView(
                title: "Daily Meal Goal",
                value: $tempMealGoal,
                unit: "meals",
                onSave: {
                    if let value = Int(tempMealGoal) {
                        Task {
                            await viewModel.updateMealGoal(value)
                        }
                    }
                    showMealGoalEdit = false
                }
            )
        }
        .sheet(isPresented: $showSleepGoalEdit) {
            GoalEditView(
                title: "Daily Sleep Goal",
                value: $tempSleepGoal,
                unit: "hours",
                onSave: {
                    if let value = Float(tempSleepGoal) {
                        Task {
                            await viewModel.updateSleepGoal(value)
                        }
                    }
                    showSleepGoalEdit = false
                }
            )
        }
    }
    
    // MARK: - Account Actions Section
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsActionRow(
                    title: "Delete Account",
                    subtitle: "Permanently delete your account and data",
                    icon: "trash.fill",
                    color: .red,
                    theme: colors
                ) {
                    showDeleteAccountConfirmation = true
                }
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
    
    // MARK: - Helper Functions
    private func loadCurrentSettings() {
        // Load current settings from user profile
        // themePreference = viewModel.profileData.themePreference ?? "system" - Removed for P2
        notificationsEnabled = viewModel.profileData.notificationsEnabled
        maxGreetingsEnabled = viewModel.profileData.maxGreetingsEnabled
        
        // Load privacy settings
//        if let privacyData = viewModel.profileData.privacySettings {
//            privacySettings = privacyData
//        }
    }
    
    private func saveSettings() async {
        // Save settings to Strapi - TODO: Implement in ProfileViewModel
        // await viewModel.updateUserSettings(
        //     notificationsEnabled: notificationsEnabled,
        //     maxGreetingsEnabled: maxGreetingsEnabled,
        //     privacySettings: privacySettings
        // )
        
        // For now, just dismiss since the method doesn't exist yet
        dismiss()
    }
    
    private func performAccountDeletion() async {
        // This will be handled by the ProfileView
        dismiss()
    }
}

// MARK: - Supporting Views
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    let content: Content
    
    init(title: String, subtitle: String, icon: String, color: Color, theme: FitGlideTheme.Colors, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.theme = theme
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            content
        }
        .padding(.vertical, 8)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: theme.primary))
        }
        .padding(.vertical, 8)
    }
}

struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    Text(subtitle)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Edit View
struct GoalEditView: View {
    let title: String
    @Binding var value: String
    let unit: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(title)
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                    
                    Text("Set your daily target")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                .padding(.top, 20)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Value")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.medium)
                        .foregroundColor(colors.onSurface)
                    
                    HStack {
                        TextField("Enter value", text: $value)
                            .font(FitGlideTheme.titleMedium)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surfaceVariant)
                            )
                            .keyboardType(.numberPad)
                        
                        Text(unit)
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.medium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Save Goal")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(colors.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
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
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
#Preview {
    let authRepo = AuthRepository()
    let strapiRepo = StrapiRepository(authRepository: authRepo)
    let profileVM = ProfileViewModel(strapiRepository: strapiRepo, authRepository: authRepo, healthService: HealthService())
    
    SettingsView(viewModel: profileVM)
} 
