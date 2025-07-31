import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showProfileSetup = false
    @State private var animateContent = false
    @State private var showWellnessQuote = false
    
    @Environment(\.colorScheme) var colorScheme
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private let onboardingData = [
        OnboardingSlide(
            title: "Namaste! 🙏",
            subtitle: "Welcome to Your Wellness Journey",
            description: "Let's create your personalized wellness profile to design the perfect nutrition and fitness plan tailored just for you.",
            icon: "person.crop.circle.badge.plus",
            color: .blue,
            indianWisdom: "Your body is your temple - treat it with respect and care."
        ),
        OnboardingSlide(
            title: "Health Vitals",
            subtitle: "Essential Wellness Metrics",
            description: "Share your height, weight, age, and activity level. This helps us calculate your daily nutrition needs and create the perfect wellness plan.",
            icon: "heart.fill",
            color: .red,
            indianWisdom: "Prevention is better than cure - stay proactive about your health."
        ),
        OnboardingSlide(
            title: "Wellness Goals",
            subtitle: "Define Your Journey",
            description: "Tell us your wellness goals - whether you want to achieve balance, build strength, or maintain your current vitality.",
            icon: "target",
            color: .green,
            indianWisdom: "Small steps today lead to big transformations tomorrow."
        ),
        OnboardingSlide(
            title: "Personalized Plans",
            subtitle: "Your Custom Wellness Path",
            description: "Based on your profile, we'll create nutrition plans with the right balance and workout routines that align with your wellness journey.",
            icon: "chart.line.uptrend.xyaxis",
            color: .purple,
            indianWisdom: "Balance in all things - mind, body, and spirit."
        )
    ]
    
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
                
                // Floating wellness elements
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 40))
                            .foregroundColor(colors.primary.opacity(0.1))
                            .offset(x: animateContent ? 30 : -30, y: animateContent ? -30 : 30)
                            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateContent)
                    }
                    Spacer()
                }
                .padding(.top, 100)
                
                VStack(spacing: 0) {
                    // Modern Header
                    modernHeaderSection
                    
                    // Content
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingData.count, id: \.self) { index in
                            ModernOnboardingSlideView(
                                slide: onboardingData[index],
                                colors: colors,
                                animateContent: $animateContent,
                                delay: Double(index) * 0.2
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                    
                    // Indian Wellness Quote
                    if showWellnessQuote {
                        indianWellnessQuoteCard
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                    
                    // Modern Navigation
                    modernNavigationSection
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
                
                // Show wellness quote after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showWellnessQuote = true
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                        Text("Skip")
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(colors.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface.opacity(0.5))
                    )
                }
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? colors.primary : colors.onSurfaceVariant.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if currentPage < onboardingData.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        showProfileSetup = true
                    }
                }) {
                    Text(currentPage < onboardingData.count - 1 ? "Next" : "Get Started")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors.primary.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Indian Wellness Quote Card
    var indianWellnessQuoteCard: some View {
        VStack(spacing: 12) {
            Text("""
                "The greatest wealth is health."
                """)
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(colors.onSurface)
            .multilineTextAlignment(.center)
            
            Text("Ancient Indian Wisdom")
                .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Modern Navigation Section
    var modernNavigationSection: some View {
        VStack(spacing: 16) {
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<onboardingData.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentPage ? colors.primary : colors.onSurfaceVariant.opacity(0.3))
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal, 20)
            
            // Action buttons
            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Previous")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(colors.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colors.onSurfaceVariant.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                Button(action: {
                    if currentPage < onboardingData.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        showProfileSetup = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(currentPage < onboardingData.count - 1 ? "Next" : "Get Started")
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.semibold)
                        
                        if currentPage < onboardingData.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.primary)
                            .shadow(color: colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Modern Onboarding Slide View
struct ModernOnboardingSlideView: View {
    let slide: OnboardingSlide
    let colors: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with animation
            ZStack {
                Circle()
                    .fill(slide.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(slide.color)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.1), value: animateContent)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.2), value: animateContent)
                
                Text(slide.subtitle)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(slide.color)
                    .multilineTextAlignment(.center)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.3), value: animateContent)
                
                Text(slide.description)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.4), value: animateContent)
                
                // Indian wisdom quote
                VStack(spacing: 8) {
                    Text("""
                        "\(slide.indianWisdom)"
                        """)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                    .italic()
                    
                    Text("Ancient Indian Wisdom")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surface.opacity(0.5))
                )
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay + 0.5), value: animateContent)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Slide Data Model
struct OnboardingSlide {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let indianWisdom: String
}

#Preview {
    OnboardingView()
} 
 