//
//  RootView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 16/06/25.
//

import Foundation
import SwiftUI

struct RootView: View {
    @StateObject var navigationViewModel = NavigationViewModel()
    @State var sleepViewModel: SleepViewModel?
    @State var mealsViewModel: MealsViewModel?
    @State var profileViewModel: ProfileViewModel?
    @State var stravaAuthViewModel: StravaAuthViewModel?
    @State var homeViewModel: HomeViewModel?
    @State var workoutViewModel: WorkoutViewModel?
    @State var strapiRepository: StrapiRepository?
    @State var healthService: HealthService?
    @State var authRepository: AuthRepository?
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView {
                    // Splash screen completed, check auth and show main content
                    Task {
                        await checkAuthenticationAndInitialize()
                        showSplash = false
                    }
                }
            } else {
                mainContent
            }
        }
        .onChange(of: authRepository?.authState.isLoggedIn) { _, newValue in
            print("🔄 Auth state changed: \(authRepository?.authState.isLoggedIn ?? false) -> \(newValue ?? false)")
            
            // Update navigation state when auth state changes
            navigationViewModel.isLoggedIn = newValue ?? false
            
            // If user logged out, clear ViewModels to force reinitialization
            if !(newValue ?? false) {
                print("🗑️ Clearing ViewModels due to logout")
                sleepViewModel = nil
                mealsViewModel = nil
                profileViewModel = nil
                stravaAuthViewModel = nil
                homeViewModel = nil
                workoutViewModel = nil
            }
            // Note: ViewModels are already initialized in checkAuthenticationAndInitialize()
            // No need to reinitialize them here
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        let isLoggedIn = navigationViewModel.isLoggedIn
        let hasAllViewModels = strapiRepository != nil && healthService != nil && authRepository != nil && 
                              sleepViewModel != nil && mealsViewModel != nil && profileViewModel != nil && 
                              stravaAuthViewModel != nil && homeViewModel != nil && workoutViewModel != nil
        
        if isLoggedIn && hasAllViewModels,
           let strapiRepository = strapiRepository,
           let healthService = healthService,
           let authRepository = authRepository,
           let sleepViewModel = sleepViewModel,
           let mealsViewModel = mealsViewModel,
           let profileViewModel = profileViewModel,
           let stravaAuthViewModel = stravaAuthViewModel,
           let homeViewModel = homeViewModel,
           let workoutViewModel = workoutViewModel {
            
            MainTabView(
                navigationViewModel: navigationViewModel,
                sleepViewModel: sleepViewModel,
                mealsViewModel: mealsViewModel,
                profileViewModel: profileViewModel,
                stravaAuthViewModel: stravaAuthViewModel,
                homeViewModel: homeViewModel,
                workoutViewModel: workoutViewModel,
                strapiRepository: strapiRepository,
                healthService: healthService,
                authRepository: authRepository
            )
            .onAppear {
                print("🏠 Showing MainTabView")
            }
        } else {
            if let authRepository = authRepository {
                LoginView(
                    navigationViewModel: navigationViewModel,
                    authRepository: authRepository
                )
                .onAppear {
                    print("🔐 Showing LoginView")
                }
            } else {
                // Fallback - should not happen but just in case
                LoginView(
                    navigationViewModel: navigationViewModel,
                    authRepository: AuthRepository(appleAuthManager: AppleAuthManager())
                )
                .onAppear {
                    print("🔐 Showing LoginView (fallback)")
                }
            }
        }
    }


    private func checkAuthenticationAndInitialize() async {
        // Initialize repositories and services
        let authRepository = AuthRepository(appleAuthManager: AppleAuthManager())
        let strapiRepository = StrapiRepository(authRepository: authRepository)
        let healthService = HealthService()

        self.authRepository = authRepository
        self.strapiRepository = strapiRepository
        self.healthService = healthService
        
        // Check authentication state FIRST
        if authRepository.authState.userId != nil && authRepository.authState.jwt != nil {
            navigationViewModel.isLoggedIn = true
        }
        
        // Initialize view models
        let sleepViewModel = await SleepViewModel(
            strapiRepository: strapiRepository,
            authRepository: authRepository
        )
        self.sleepViewModel = sleepViewModel

        self.mealsViewModel = MealsViewModel(
            strapi: strapiRepository,
            auth: authRepository
        )

        self.profileViewModel = ProfileViewModel(
            strapiRepository: strapiRepository,
            authRepository: authRepository,
            healthService: healthService
        )

        self.stravaAuthViewModel = StravaAuthViewModel(
            authRepository: authRepository
        )

        self.workoutViewModel = WorkoutViewModel(
            strapiRepository: strapiRepository,
            healthService: healthService,
            authRepository: authRepository
        )

        self.homeViewModel = HomeViewModel(
            strapiRepository: strapiRepository,
            authRepository: authRepository,
            healthService: healthService,
        )
    }

    private func initializeViewModelsIfNeeded() async {
        // This method is kept for potential future use but is not currently needed
        // since ViewModels are initialized in checkAuthenticationAndInitialize()
        print("📝 initializeViewModelsIfNeeded called - ViewModels already initialized")
    }
}
