//
//  NotificationManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // Request permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notifications permission granted")
            } else {
                print("❌ Notifications permission denied: \(error?.localizedDescription ?? "unknown error")")
            }
        }

        // Define actions
        let shareAction = UNNotificationAction(
            identifier: "SHARE_WORKOUT",
            title: "Share Now",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: "LIVE_WORKOUT",
            actions: [shareAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // Foreground notification display
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Action handling
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "SHARE_WORKOUT" {
            print("🎉 User chose to share workout live")
            // TODO: Trigger CheersViewModel or appropriate handler
        }
        completionHandler()
    }
}
