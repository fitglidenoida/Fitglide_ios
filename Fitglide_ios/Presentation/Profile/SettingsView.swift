import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ProfileViewModel
    @State private var animateContent = false
    @State private var showDeleteAccountConfirmation = false
    
    // Settings state
    @State private var themePreference: String = "system"
    @State private var notificationsEnabled: Bool = true
    @State private var maxGreetingsEnabled: Bool = true
    @State private var privacySettings: [String: Bool] = [
        "profileVisible": true,
        "activityVisible": true,
        "achievementsVisible": true,
        "allowFriendRequests": true
    ]
    
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
                        
                        // Appearance Settings
                        appearanceSection
                        
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
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Appearance")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsRow(
                    title: "Theme",
                    subtitle: "Choose your preferred theme",
                    icon: "paintbrush.fill",
                    color: .purple,
                    theme: colors
                ) {
                    HStack {
                        Picker("Theme", selection: $themePreference) {
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                            Text("System").tag("system")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        
                        Spacer()
                    }
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Helper Functions
    private func loadCurrentSettings() {
        // Load current settings from user profile
        themePreference = viewModel.profileData.themePreference ?? "system"
        notificationsEnabled = viewModel.profileData.notificationsEnabled
        maxGreetingsEnabled = viewModel.profileData.maxGreetingsEnabled
        
        // Load privacy settings
//        if let privacyData = viewModel.profileData.privacySettings {
//            privacySettings = privacyData
//        }
    }
    
    private func saveSettings() async {
        // Save settings to Strapi
        await viewModel.updateUserSettings(
            themePreference: themePreference,
            notificationsEnabled: notificationsEnabled,
            maxGreetingsEnabled: maxGreetingsEnabled,
//            privacySettings: privacySettings
        )
        
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

// MARK: - Preview
#Preview {
    let authRepo = AuthRepository()
    let strapiRepo = StrapiRepository(authRepository: authRepo)
    let profileVM = ProfileViewModel(strapiRepository: strapiRepo, authRepository: authRepo, healthService: HealthService())
    
    SettingsView(viewModel: profileVM)
} 
