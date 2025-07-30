//
//  MainTabView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 16/06/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    @State private var date = Date()
    @Environment(\.colorScheme) var colorScheme
    
    // ViewModels
    let sleepViewModel: SleepViewModel
    let mealsViewModel: MealsViewModel
    let profileViewModel: ProfileViewModel
    let stravaAuthViewModel: StravaAuthViewModel
    let homeViewModel: HomeViewModel
    let workoutViewModel: WorkoutViewModel
    let strapiRepository: StrapiRepository
    let healthService: HealthService
    let authRepository: AuthRepository
    
    // Services for new features
    @StateObject private var analyticsService: AnalyticsService
    @StateObject private var smartNotificationService: SmartNotificationService
    @StateObject private var periodsViewModel: PeriodsViewModel

    init(navigationViewModel: NavigationViewModel,
         sleepViewModel: SleepViewModel,
         mealsViewModel: MealsViewModel,
         profileViewModel: ProfileViewModel,
         stravaAuthViewModel: StravaAuthViewModel,
         homeViewModel: HomeViewModel,
         workoutViewModel: WorkoutViewModel,
         strapiRepository: StrapiRepository,
         healthService: HealthService,
         authRepository: AuthRepository) {
        
        self.navigationViewModel = navigationViewModel
        self.sleepViewModel = sleepViewModel
        self.mealsViewModel = mealsViewModel
        self.profileViewModel = profileViewModel
        self.stravaAuthViewModel = stravaAuthViewModel
        self.homeViewModel = homeViewModel
        self.workoutViewModel = workoutViewModel
        self.strapiRepository = strapiRepository
        self.healthService = healthService
        self.authRepository = authRepository
        
        // Initialize new services
        self._analyticsService = StateObject(wrappedValue: AnalyticsService(healthService: healthService, strapiRepository: strapiRepository, authRepository: authRepository))
        self._smartNotificationService = StateObject(wrappedValue: SmartNotificationService(healthService: healthService, strapiRepository: strapiRepository, authRepository: authRepository))
        self._periodsViewModel = StateObject(wrappedValue: PeriodsViewModel(healthService: healthService, strapiRepository: strapiRepository, authRepository: authRepository))
    }

    var body: some View {
        ZStack {
            // Background
            FitGlideTheme.colors(for: colorScheme).background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ModernHeader()
                
                // Main Content
                TabView(selection: $navigationViewModel.selectedTab) {
                    // Home Tab
                    HomeView(viewModel: homeViewModel, date: $date)
                        .tag(NavigationViewModel.Tab.home)
                    
                    // Workout Tab
                    WorkoutView(
                        userName: authRepository.authState.firstName ?? "User",
                        navigationViewModel: navigationViewModel,
                        viewModel: workoutViewModel
                    )
                    .tag(NavigationViewModel.Tab.workout)
                    
                    // Meals Tab
                    MealsView(viewModel: mealsViewModel)
                        .tag(NavigationViewModel.Tab.meals)
                    
                    // Sleep Tab
                    SleepView(viewModel: sleepViewModel)
                        .tag(NavigationViewModel.Tab.sleep)
                    
                    // Analytics Tab
                    AnalyticsView(analyticsService: analyticsService)
                        .tag(NavigationViewModel.Tab.analytics)
                    
                    // Profile Tab
                    ProfileView(
                        viewModel: profileViewModel,
                        stravaAuthViewModel: stravaAuthViewModel,
                        navigationViewModel: navigationViewModel,
                        authRepository: authRepository
                    )
                    .tag(NavigationViewModel.Tab.profile)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom Modern Tab Bar
                ModernTabBar(navigationViewModel: navigationViewModel)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// MARK: - Modern Header
struct ModernHeader: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            // Logo and Title
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    .font(.title2)
                
                Text("FitGlide")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onBackground)
            }
            
            Spacer()
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                }
                
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            FitGlideTheme.colors(for: colorScheme).surface
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Tab Bar
struct ModernTabBar: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(navigationViewModel: NavigationViewModel) {
        self.navigationViewModel = navigationViewModel
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(NavigationViewModel.Tab.allCases, id: \.self) { tab in
                ModernTabButton(
                    tab: tab,
                    isSelected: navigationViewModel.selectedTab == tab,
                    action: { navigationViewModel.selectTab(tab) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            FitGlideTheme.colors(for: colorScheme).surface
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: -4)
        )
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

// MARK: - Modern Tab Button
struct ModernTabButton: View {
    let tab: NavigationViewModel.Tab
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).primary : FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                
                Text(tab.title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).primary : FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Placeholder View (for any future use)
struct PlaceholderView: View {
    let title: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            
            Text(title)
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            
            Spacer()
        }
        .background(FitGlideTheme.colors(for: colorScheme).background)
    }
}
