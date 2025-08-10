//
//  Fitglide_iosApp.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import SwiftUI

@main
struct Fitglide_iosApp: App {
    @StateObject private var achievementManager = AchievementManager.shared
    
    init() {
        NotificationManager.shared.setupNotifications()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(achievementManager)
                .overlay(
                    AchievementNotificationOverlay(achievementManager: achievementManager)
                )
        }
    }
}
