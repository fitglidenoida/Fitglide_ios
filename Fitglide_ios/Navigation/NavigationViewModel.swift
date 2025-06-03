//
//  NavigationState.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/06/25.
//

import Foundation
import SwiftUI

class NavigationViewModel: ObservableObject {
    enum Tab: Int, Hashable {
        case home, workout, meals, sleep, profile
    }

    @Published var selectedTab: Tab = .home
    @Published var isLoggedIn: Bool = false

    func navigateToLogin() {
        isLoggedIn = false
    }

    func navigateToMainApp() {
        isLoggedIn = true
    }
}
