import SwiftUI

struct OnboardingDemoView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showOnboarding = false
    @State private var currentProfileData: ProfileData?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Onboarding Demo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Test the onboarding flow and profile setup banners")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Profile completion status
                    if let profileData = currentProfileData {
                        ProfileCompletionCard(
                            profileData: profileData,
                            completionPercentage: onboardingManager.getProfileCompletionPercentage(profileData: profileData)
                        )
                    }
                    
                    // Demo banners
                    VStack(spacing: 16) {
                        Text("Demo Banners")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Home banner
                        if onboardingManager.shouldShowBanner(for: "home") {
                            ContextualBanner(
                                viewType: .home,
                                profileData: currentProfileData,
                                colorScheme: .light
                            ) {
                                showOnboarding = true
                            }
                        }
                        
                        // Meals banner
                        if onboardingManager.shouldShowBanner(for: "meals") {
                            ContextualBanner(
                                viewType: .meals,
                                profileData: currentProfileData,
                                colorScheme: .light
                            ) {
                                showOnboarding = true
                            }
                        }
                        
                        // Workout banner
                        if onboardingManager.shouldShowBanner(for: "workout") {
                            ContextualBanner(
                                viewType: .workout,
                                profileData: currentProfileData,
                                colorScheme: .light
                            ) {
                                showOnboarding = true
                            }
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showOnboarding = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                Text("Start Onboarding")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button(action: {
                            // Simulate incomplete profile
                            currentProfileData = ProfileData(
                                firstName: "",
                                lastName: "",
                                height: 0,
                                weight: 0,
                                age: 0,
                                activityLevel: "",
                                fitnessGoal: ""
                            )
                        }) {
                            Text("Simulate Incomplete Profile")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            // Simulate complete profile
                            currentProfileData = ProfileData(
                                firstName: "John",
                                lastName: "Doe",
                                height: 175,
                                weight: 70,
                                age: 30,
                                activityLevel: "Moderate exercise (3-5 days/week)",
                                fitnessGoal: "Lose weight"
                            )
                        }) {
                            Text("Simulate Complete Profile")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            onboardingManager.dismissedBanners.removeAll()
                            onboardingManager.dismissedBanners = []
                        }) {
                            Text("Reset Dismissed Banners")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            // Start with incomplete profile
            currentProfileData = ProfileData(
                firstName: "",
                lastName: "",
                height: 0,
                weight: 0,
                age: 0,
                activityLevel: "",
                fitnessGoal: ""
            )
        }
    }
}

struct ProfileCompletionCard: View {
    let profileData: ProfileData
    let completionPercentage: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Profile Completion")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(completionPercentage * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(completionPercentage >= 1.0 ? .green : .orange)
            }
            
            ProgressView(value: completionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: completionPercentage >= 1.0 ? .green : .blue))
                .frame(height: 8)
            
            // Missing fields
            if completionPercentage < 1.0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Missing:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if profileData.firstName.isEmpty || profileData.lastName.isEmpty {
                        Text("• Basic information (name)")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    if profileData.height <= 0 || profileData.weight <= 0 || profileData.age <= 0 {
                        Text("• Health vitals (height, weight, age)")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    if profileData.activityLevel.isEmpty {
                        Text("• Activity level")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    if profileData.fitnessGoal.isEmpty {
                        Text("• Fitness goals")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingDemoView()
} 