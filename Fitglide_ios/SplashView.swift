//
//  SplashView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 22/07/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showLoading = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var loadingOpacity: Double = 0
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.4, blue: 0.8),
                    Color(red: 0.3, green: 0.6, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and branding
                VStack(spacing: 20) {
                    // App Icon/Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                    }
                    
                    // App Name
                    Text("FitGlide")
                        .font(.custom("Poppins-Bold", size: 36))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                    
                    // Tagline
                    Text("Your Journey to Better Health")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(taglineOpacity)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 15) {
                    // Animated dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .opacity(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                    
                    Text("Loading...")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(loadingOpacity)
                }
                .opacity(loadingOpacity)
                
                Spacer()
                
                // Version info
                VStack(spacing: 5) {
                    Text("Version 1.0.0")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("© 2025 FitGlide. All rights reserved.")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Start the continuous animation
        isAnimating = true
        
        // Animate logo appearance
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate tagline appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                taglineOpacity = 1.0
            }
        }
        
        // Animate loading indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                loadingOpacity = 1.0
            }
        }
        
        // Complete splash screen after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                logoOpacity = 0
                taglineOpacity = 0
                loadingOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Preview
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView {
            print("Splash completed")
        }
    }
}

// MARK: - Splash View Model
@MainActor
class SplashViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var showMainApp = false
    
    private let authRepository: AuthRepository
    private let healthService: HealthService
    
    init(authRepository: AuthRepository, healthService: HealthService) {
        self.authRepository = authRepository
        self.healthService = healthService
    }
    
    func initializeApp() async {
        // Simulate initialization tasks
        await performInitializationTasks()
        
        // Check authentication status
        await checkAuthenticationStatus()
        
        // Request health permissions if needed
        await requestHealthPermissions()
        
        // Complete initialization
        await MainActor.run {
            self.isLoading = false
            self.showMainApp = true
        }
    }
    
    private func performInitializationTasks() async {
        // Simulate app initialization tasks
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Load user preferences
        // Initialize services
        // Load cached data
    }
    
    private func checkAuthenticationStatus() async {
        // Check if user is logged in
        if authRepository.isLoggedIn() {
            // User is authenticated, load their data
            print("User is authenticated")
        } else {
            // User needs to log in
            print("User needs authentication")
        }
    }
    
    private func requestHealthPermissions() async {
        do {
            try await healthService.requestAuthorization()
            print("Health permissions granted")
        } catch {
            print("Health permissions failed: \(error.localizedDescription)")
        }
    }
}
