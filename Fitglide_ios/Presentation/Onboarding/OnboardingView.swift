import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showProfileSetup = false
    
    private let onboardingData = [
        OnboardingSlide(
            title: "Welcome to FitGlide!",
            subtitle: "Your personalized fitness journey starts here",
            description: "Let's set up your profile to create customized meal and workout plans tailored just for you.",
            icon: "person.crop.circle.badge.plus",
            color: .blue
        ),
        OnboardingSlide(
            title: "Health Vitals",
            subtitle: "Essential health metrics",
            description: "Update your height, weight, age, and activity level. This helps us calculate your daily calorie needs and create the perfect meal plan.",
            icon: "heart.fill",
            color: .red
        ),
        OnboardingSlide(
            title: "Fitness Goals",
            subtitle: "Define your objectives",
            description: "Tell us your goals - whether you want to lose weight, gain muscle, or maintain your current fitness level.",
            icon: "target",
            color: .green
        ),
        OnboardingSlide(
            title: "Personalized Plans",
            subtitle: "Your custom nutrition & workouts",
            description: "Based on your profile, we'll create meal plans with the right calories and macros, plus workout routines that match your goals.",
            icon: "chart.line.uptrend.xyaxis",
            color: .purple
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Skip") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingData.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            if currentPage < onboardingData.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            } else {
                                showProfileSetup = true
                            }
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Content
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            OnboardingSlideView(slide: onboardingData[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                    
                    // Bottom action
                    VStack(spacing: 16) {
                        if currentPage == onboardingData.count - 1 {
                            Button(action: {
                                showProfileSetup = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 18))
                                    Text("Set Up Profile")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        Button("I'll do this later") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showProfileSetup) {
            ProfileSetupView()
        }
    }
}

struct OnboardingSlide {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(slide.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(slide.color)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(slide.subtitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(slide.color)
                    .multilineTextAlignment(.center)
                
                Text(slide.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Complete Your Profile")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("This will help us create personalized meal and workout plans just for you.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Setup steps
                VStack(spacing: 16) {
                    SetupStepCard(
                        title: "Health Vitals",
                        description: "Height, weight, age, activity level",
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    SetupStepCard(
                        title: "Fitness Goals",
                        description: "Weight loss, muscle gain, or maintenance",
                        icon: "target",
                        color: .green
                    )
                    
                    SetupStepCard(
                        title: "Preferences",
                        description: "Dietary restrictions and workout preferences",
                        icon: "gear",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Navigate to profile
                        dismiss()
                        // TODO: Navigate to profile tab
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 18))
                            Text("Go to Profile")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

struct SetupStepCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView()
} 