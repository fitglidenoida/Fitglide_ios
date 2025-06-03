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
    let sleepViewModel: SleepViewModel
    let mealsViewModel: MealsViewModel
    let profileViewModel: ProfileViewModel
    let stravaAuthViewModel: StravaAuthViewModel
    let homeViewModel: HomeViewModel
    let workoutViewModel: WorkoutViewModel
    let strapiRepository: StrapiRepository
    let healthService: HealthService
    let authRepository: AuthRepository

    var body: some View {
        VStack(spacing: 0) {
            // Top Header
            HStack {
                Text("FitGlide")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                Spacer()
            }
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)

            // Bottom TabView
            TabView(selection: $navigationViewModel.selectedTab) {
                HomeView(viewModel: homeViewModel, date: $date)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(NavigationViewModel.Tab.home)

                WorkoutView(
                    userName: authRepository.authState.firstName ?? "User",
                    navigationViewModel: navigationViewModel,
                    viewModel: workoutViewModel,
                )
                    .tabItem {
                        Label("Workouts", systemImage: "figure.walk")
                    }
                    .tag(NavigationViewModel.Tab.workout)

                MealsView(viewModel: mealsViewModel)
                    .tabItem {
                        Label("Meals", systemImage: "fork.knife")
                    }
                    .tag(NavigationViewModel.Tab.meals)

                SleepView(viewModel: sleepViewModel)
                    .tabItem {
                        Label("Sleep", systemImage: "moon.fill")
                    }
                    .tag(NavigationViewModel.Tab.sleep)

                ProfileView(
                    viewModel: profileViewModel,
                    stravaAuthViewModel: stravaAuthViewModel,
                    navigationViewModel: navigationViewModel,
                    authRepository: authRepository
                )
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(NavigationViewModel.Tab.profile)
            }
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}
