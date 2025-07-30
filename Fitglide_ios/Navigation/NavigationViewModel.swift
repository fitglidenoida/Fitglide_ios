//
//  NavigationState.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/06/25.
//

import Foundation
import SwiftUI

class NavigationViewModel: ObservableObject {
    enum Tab: Int, Hashable, CaseIterable {
        case home, workout, meals, sleep, analytics, profile
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .workout: return "Workouts"
            case .meals: return "Meals"
            case .sleep: return "Sleep"
            case .analytics: return "Analytics"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .workout: return "figure.walk"
            case .meals: return "fork.knife"
            case .sleep: return "moon.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .profile: return "person.fill"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .workout: return "figure.walk"
            case .meals: return "fork.knife"
            case .sleep: return "moon.fill"
            case .analytics: return "chart.line.uptrend.xyaxis.circle.fill"
            case .profile: return "person.fill"
            }
        }
    }

    @Published var selectedTab: Tab = .home
    @Published var isLoggedIn: Bool = false
    @Published var showTabBar: Bool = true
    
    // Modern navigation features
    @Published var navigationStack: [Tab] = []
    @Published var showBackButton: Bool = false

    func navigateToLogin() {
        isLoggedIn = false
    }

    func navigateToMainApp() {
        isLoggedIn = true
    }
    
    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func pushTab(_ tab: Tab) {
        navigationStack.append(tab)
        showBackButton = true
    }
    
    func popTab() {
        _ = navigationStack.popLast()
        showBackButton = !navigationStack.isEmpty
    }
}
