//
//  Login.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    @ObservedObject var authRepository: AuthRepository
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var animateContent = false
    @State private var showWelcomeMessage = false

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)

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
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colors.primary.opacity(0.1))
                        .offset(x: animateContent ? 20 : -20, y: animateContent ? -20 : 20)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateContent)
                }
                Spacer()
            }
            .padding(.top, 100)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and Welcome Section
                VStack(spacing: 24) {
                    // Logo with animation
                    ZStack {
                        Circle()
                            .fill(colors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateContent ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateContent)
                        
                        Image("Fitglide_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .scaleEffect(animateContent ? 1.0 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
                    }
                    
                    // Welcome Text
                    VStack(spacing: 12) {
                        Text("Namaste! 🙏")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(colors.onSurface)
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Text("Welcome to FitGlide")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.primary)
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                        
                        Text("Sign in to begin your holistic wellness journey")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                }
                
                Spacer()
                
                // Indian Wellness Quote
                if showWelcomeMessage {
                    VStack(spacing: 12) {
                        Text("""
                            "Health is wealth - your body is your greatest asset."
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                
                Spacer()
                
                // Authentication Section
                VStack(spacing: 20) {
                    // Apple Sign In Button
                    ModernAppleSignInButton(
                        authRepository: authRepository,
                        navigationViewModel: navigationViewModel,
                        colors: colors,
                        animateContent: $animateContent
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Authentication"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            
            // Show welcome message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showWelcomeMessage = true
                }
            }
        }
    }
}

// MARK: - Modern Apple Sign In Button
struct ModernAppleSignInButton: View {
    @ObservedObject var authRepository: AuthRepository
    @ObservedObject var navigationViewModel: NavigationViewModel
    let colors: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                authRepository.loginWithApple { success in
                    if success {
                        // RootView will automatically navigate when auth state changes
                        print("✅ Login successful - RootView will handle navigation")
                        
                        // Backup: Manual navigation in case onChange doesn't trigger
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if authRepository.authState.isLoggedIn {
                                print("🔄 Manual navigation trigger")
                                navigationViewModel.navigateToMainApp()
                            }
                        }
                    } else {
                        alertMessage = "Login failed. Please try again."
                        showingAlert = true
                    }
                }
            }
        )
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(animateContent ? 1.0 : 0.9)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Authentication"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    LoginView(navigationViewModel: NavigationViewModel(), authRepository: AuthRepository(appleAuthManager: AppleAuthManager()))
}
