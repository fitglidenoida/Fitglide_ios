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
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if navigationViewModel.isLoggedIn,
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
        } else {
            LoginView(
                navigationViewModel: navigationViewModel,
            )
        }
    }


    private func initializeViewModels() async {
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
}
