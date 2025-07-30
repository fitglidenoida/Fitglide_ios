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
        primary: Color(hex: "007AFF"), // Modern iOS Blue
        secondary: Color(hex: "FF6B9D"), // Modern Pink for periods/health
        tertiary: Color(hex: "FF9500"), // Modern Orange
        quaternary: Color(hex: "34C759"), // Modern Green
        background: Color(hex: "F8F9FA"), // Modern light background
        surface: Color.white,
        onPrimary: Color.white,
        onSecondary: Color.white,
        onTertiary: Color.black,
        onQuaternary: Color.white,
        onBackground: Color(hex: "1C1C1E"), // Modern dark text
        onSurface: Color(hex: "1C1C1E"),
        onSurfaceVariant: Color(hex: "6C6C70"), // Modern medium gray
        surfaceVariant: Color(hex: "F2F2F7") // Modern light gray
    )
    
    static let darkColors = Colors(
        primary: Color(hex: "0A84FF"), // Modern dark mode blue
        secondary: Color(hex: "FF6B9D"), // Modern pink (same as light)
        tertiary: Color(hex: "FF9F0A"), // Modern dark mode orange
        quaternary: Color(hex: "30D158"), // Modern dark mode green
        background: Color(hex: "000000"), // Pure black
        surface: Color(hex: "1C1C1E"), // Modern dark surface
        onPrimary: Color.white,
        onSecondary: Color.white,
        onTertiary: Color.black,
        onQuaternary: Color.black,
        onBackground: Color(hex: "FFFFFF"), // Pure white
        onSurface: Color(hex: "FFFFFF"),
        onSurfaceVariant: Color(hex: "EBEBF5"), // Modern light text
        surfaceVariant: Color(hex: "2C2C2E") // Modern dark variant
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
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
    }
    
    struct Card {
        static let cornerRadius: CGFloat = 16
        static let elevation: CGFloat = 8 // For shadow
        static let smallCornerRadius: CGFloat = 12
    }
    
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
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
