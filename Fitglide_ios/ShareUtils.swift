//
//  ShareUtils.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 20/07/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - ShareUtils
@MainActor
class ShareUtils {
    static let shared = ShareUtils()
    
    private init() {}
    
    // MARK: - Achievement Sharing
    func shareAchievement(
        title: String,
        description: String,
        image: UIImage? = nil,
        from viewController: UIViewController? = nil
    ) {
        var items: [Any] = [
            "🏆 \(title)\n\(description)\n\nAchieved with FitGlide! 💪"
        ]
        
        if let image = image {
            items.append(image)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let viewController = viewController {
            viewController.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Workout Sharing
    func shareWorkout(
        steps: Int,
        calories: Int,
        distance: Double? = nil,
        duration: TimeInterval? = nil,
        from viewController: UIViewController? = nil
    ) {
        var workoutText = "🔥 Just completed my workout!\n"
        workoutText += "👟 Steps: \(steps)\n"
        workoutText += "🔥 Calories: \(calories)\n"
        
        if let distance = distance {
            workoutText += "📏 Distance: \(String(format: "%.2f", distance)) km\n"
        }
        
        if let duration = duration {
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            workoutText += "⏱️ Duration: \(hours)h \(minutes)m\n"
        }
        
        workoutText += "\nTracked with FitGlide! 🚀"
        
        let activityVC = UIActivityViewController(activityItems: [workoutText], applicationActivities: nil)
        
        if let viewController = viewController {
            viewController.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Meal Sharing
    func shareMeal(
        mealName: String,
        calories: Int,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        image: UIImage? = nil,
        from viewController: UIViewController? = nil
    ) {
        var mealText = "🍽️ \(mealName)\n"
        mealText += "🔥 Calories: \(calories)\n"
        
        if let protein = protein {
            mealText += "🥩 Protein: \(String(format: "%.1f", protein))g\n"
        }
        if let carbs = carbs {
            mealText += "🍞 Carbs: \(String(format: "%.1f", carbs))g\n"
        }
        if let fat = fat {
            mealText += "🥑 Fat: \(String(format: "%.1f", fat))g\n"
        }
        
        mealText += "\nTracked with FitGlide! 🥗"
        
        var items: [Any] = [mealText]
        if let image = image {
            items.append(image)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let viewController = viewController {
            viewController.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Progress Sharing
    func shareProgress(
        weightLost: Double? = nil,
        stepsGoal: Int? = nil,
        streak: Int? = nil,
        from viewController: UIViewController? = nil
    ) {
        var progressText = "📈 My FitGlide Progress!\n\n"
        
        if let weightLost = weightLost {
            progressText += "⚖️ Weight Lost: \(String(format: "%.1f", weightLost)) kg\n"
        }
        
        if let stepsGoal = stepsGoal {
            progressText += "👟 Daily Goal: \(stepsGoal) steps\n"
        }
        
        if let streak = streak {
            progressText += "🔥 Streak: \(streak) days\n"
        }
        
        progressText += "\nJoin me on FitGlide! 💪"
        
        let activityVC = UIActivityViewController(activityItems: [progressText], applicationActivities: nil)
        
        if let viewController = viewController {
            viewController.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Generic Content Sharing
    func shareContent(
        title: String,
        message: String,
        image: UIImage? = nil,
        url: URL? = nil,
        from viewController: UIViewController? = nil
    ) {
        var items: [Any] = ["\(title)\n\n\(message)"]
        
        if let image = image {
            items.append(image)
        }
        
        if let url = url {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let viewController = viewController {
            viewController.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Image Generation for Sharing
    func generateShareImage(
        title: String,
        subtitle: String,
        backgroundColor: UIColor = .systemBlue,
        textColor: UIColor = .white
    ) -> UIImage? {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Gradient overlay
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(origin: .zero, size: size)
            gradient.colors = [
                backgroundColor.cgColor,
                backgroundColor.withAlphaComponent(0.8).cgColor
            ]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 1)
            
            // Text attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: textColor
            ]
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: textColor.withAlphaComponent(0.9)
            ]
            
            // Draw text
            let titleRect = CGRect(x: 40, y: 120, width: size.width - 80, height: 60)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            let subtitleRect = CGRect(x: 40, y: 200, width: size.width - 80, height: 40)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            
            // FitGlide logo/branding
            let brandText = "FitGlide"
            let brandAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: textColor.withAlphaComponent(0.7)
            ]
            
            let brandRect = CGRect(x: 40, y: size.height - 60, width: 200, height: 30)
            brandText.draw(in: brandRect, withAttributes: brandAttributes)
        }
    }
}

// MARK: - SwiftUI Extensions
extension View {
    func shareAchievement(title: String, description: String) {
        ShareUtils.shared.shareAchievement(title: title, description: description)
    }
    
    func shareWorkout(steps: Int, calories: Int, distance: Double? = nil, duration: TimeInterval? = nil) {
        ShareUtils.shared.shareWorkout(steps: steps, calories: calories, distance: distance, duration: duration)
    }
    
    func shareMeal(mealName: String, calories: Int, protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil) {
        ShareUtils.shared.shareMeal(mealName: mealName, calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
    
    func shareProgress(weightLost: Double? = nil, stepsGoal: Int? = nil, streak: Int? = nil) {
        ShareUtils.shared.shareProgress(weightLost: weightLost, stepsGoal: stepsGoal, streak: streak)
    }
}
