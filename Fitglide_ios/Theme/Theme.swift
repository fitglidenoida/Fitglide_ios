//
//  Theme.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import Foundation
import SwiftUI

struct FitGlideTheme {
    struct Colors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
        let quaternary: Color // Added for green (fiber)
        let background: Color
        let surface: Color
        let onPrimary: Color
        let onSecondary: Color
        let onTertiary: Color
        let onQuaternary: Color
        let onBackground: Color
        let onSurface: Color
        let onSurfaceVariant: Color
        let surfaceVariant: Color
    }
    
    static let lightColors = Colors(
        primary: Color(hex: "007AFF"), // Blue (iOS system blue, matches MealsView)
        secondary: Color(hex: "6A1B9A"), // Purple (matches MealsView)
        tertiary: Color(hex: "FF9500"), // Orange (matches MealsView)
        quaternary: Color(hex: "4CAF50"), // Green (matches MealsView for fiber)
        background: Color(hex: "F5F5F5"), // Light gray (unchanged)
        surface: Color.white,
        onPrimary: Color.white,
        onSecondary: Color.white,
        onTertiary: Color.black,
        onQuaternary: Color.white,
        onBackground: Color(hex: "212121"), // Dark gray
        onSurface: Color(hex: "212121"),
        onSurfaceVariant: Color(hex: "757575"), // Medium gray
        surfaceVariant: Color(hex: "E0E0E0") // Light gray
    )
    
    static let darkColors = Colors(
        primary: Color(hex: "82B1FF"), // Lighter Blue
        secondary: Color(hex: "AB47BC"), // Lighter Purple
        tertiary: Color(hex: "FFB300"), // Lighter Orange
        quaternary: Color(hex: "81C784"), // Lighter Green
        background: Color(hex: "121212"), // Dark gray
        surface: Color(hex: "1E1E1E"), // Darker gray
        onPrimary: Color.black,
        onSecondary: Color.black,
        onTertiary: Color.black,
        onQuaternary: Color.black,
        onBackground: Color(hex: "E0E0E0"), // Light gray
        onSurface: Color(hex: "E0E0E0"),
        onSurfaceVariant: Color(hex: "B0BEC5"), // Light gray-blue
        surfaceVariant: Color(hex: "424242") // Dark gray
    )
    
    static func colors(for colorScheme: ColorScheme) -> Colors {
        colorScheme == .dark ? darkColors : lightColors
    }
    
    // Typography (aligned with Material 3 defaults)
    static let titleLarge = Font.custom("Poppins-Bold", size: 22)
    static let titleMedium = Font.custom("Poppins-SemiBold", size: 16)
    static let bodyLarge = Font.custom("Poppins-Regular", size: 16)
    static let bodyMedium = Font.custom("Poppins-Regular", size: 14)
    static let caption = Font.custom("Poppins-Regular", size: 12)
    
    // Component styles
    struct Button {
        static let cornerRadius: CGFloat = 8
        static let padding: CGFloat = 16
    }
    
    struct Card {
        static let cornerRadius: CGFloat = 12
        static let elevation: CGFloat = 4 // For shadow
    }
}

// Extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
