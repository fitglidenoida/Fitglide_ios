import SwiftUI

struct ProfileSetupBanner: View {
    @State private var showOnboarding = false
    @State private var showProfile = false
    let profileData: ProfileData?
    let colorScheme: ColorScheme
    let onSetupTap: (() -> Void)?
    
    init(profileData: ProfileData?, colorScheme: ColorScheme, onSetupTap: (() -> Void)? = nil) {
        self.profileData = profileData
        self.colorScheme = colorScheme
        self.onSetupTap = onSetupTap
    }
    
    var body: some View {
        if shouldShowBanner {
            HStack(spacing: 12) {
                // House icon
                ZStack {
                    Circle()
                        .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Complete Your Profile")
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                    
                    Text("Complete your profile to unlock all features")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Setup button
                Button(action: {
                    onSetupTap?()
                }) {
                    Text("Setup")
                        .font(.custom("Poppins-Semibold", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(FitGlideTheme.colors(for: colorScheme).primary)
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    private var shouldShowBanner: Bool {
        guard let profile = profileData else { return true }
        
        // Check if essential profile data is missing
        let hasBasicInfo = !profile.firstName.isEmpty && !profile.lastName.isEmpty
        let hasHealthVitals = profile.height > 0 && profile.weight > 0 && profile.age > 0
        let hasActivityLevel = !profile.activityLevel.isEmpty
        let hasGoals = !profile.fitnessGoal.isEmpty
        
        return !hasBasicInfo || !hasHealthVitals || !hasActivityLevel || !hasGoals
    }
}

// Profile data structure for banner logic
public struct ProfileData {
    let firstName: String
    let lastName: String
    let height: Float
    let weight: Float
    let age: Int
    let activityLevel: String
    let fitnessGoal: String
}

// Contextual banner for specific views
struct ContextualBanner: View {
    let viewType: BannerViewType
    let profileData: ProfileData?
    let colorScheme: ColorScheme
    let onAction: () -> Void
    
    enum BannerViewType {
        case meals
        case workout
        case home
        case social
    }
    
    var body: some View {
        if shouldShowBanner {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon based on view type
                    ZStack {
                        Circle()
                            .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: iconForViewType)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titleForViewType)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        
                        Text(descriptionForViewType)
                            .font(.system(size: 13))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onAction) {
                        Text("Setup")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1))
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FitGlideTheme.colors(for: colorScheme).surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(FitGlideTheme.colors(for: colorScheme).primary.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var shouldShowBanner: Bool {
        guard let profile = profileData else { return true }
        
        switch viewType {
        case .meals:
            return profile.height <= 0 || profile.weight <= 0 || profile.activityLevel.isEmpty
        case .workout:
            return profile.fitnessGoal.isEmpty
        case .home:
            return profile.firstName.isEmpty || profile.height <= 0 || profile.fitnessGoal.isEmpty
        case .social:
            return profile.firstName.isEmpty || profile.lastName.isEmpty
        }
    }
    
    private var iconForViewType: String {
        switch viewType {
        case .meals: return "fork.knife"
        case .workout: return "dumbbell.fill"
        case .home: return "house.fill"
        case .social: return "person.2.fill"
        }
    }
    
    private var titleForViewType: String {
        switch viewType {
        case .meals: return "Personalized Meal Plans"
        case .workout: return "Custom Workout Plans"
        case .home: return "Complete Your Profile"
        case .social: return "Connect with Friends"
        }
    }
    
    private var descriptionForViewType: String {
        switch viewType {
        case .meals: return "Update your health vitals to get customized meal plans"
        case .workout: return "Set your fitness goals to get personalized workout routines"
        case .home: return "Complete your profile to unlock all features"
        case .social: return "Add your name to connect with friends"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileSetupBanner(
            profileData: nil,
            colorScheme: .light
        )
        
        ContextualBanner(
            viewType: .meals,
            profileData: nil,
            colorScheme: .light
        ) {
            print("Setup tapped")
        }
    }
    .padding()
} 