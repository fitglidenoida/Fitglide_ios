import SwiftUI

struct WatchTheme {
    struct Colors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
        let quaternary: Color
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
    
    // FitGlide Watch Theme - Aligned with main app design philosophy
    static let colors = Colors(
        primary: Color(hex: "007AFF"), // Modern iOS Blue (matches main app)
        secondary: Color(hex: "FF6B9D"), // Modern Pink (matches main app)
        tertiary: Color(hex: "FF9500"), // Modern Orange (matches main app)
        quaternary: Color(hex: "34C759"), // Modern Green (matches main app)
        background: Color(hex: "000000"), // Pure black for OLED
        surface: Color(hex: "1C1C1E"), // Dark surface
        onPrimary: Color.white,
        onSecondary: Color.white,
        onTertiary: Color.black,
        onQuaternary: Color.white,
        onBackground: Color.white,
        onSurface: Color.white,
        onSurfaceVariant: Color(hex: "6C6C70"), // Modern medium gray (matches main app)
        surfaceVariant: Color(hex: "2C2C2E") // Dark surface variant
    )
    
    // Gradient colors matching main app
    static let gradients = Gradients(
        primary: LinearGradient(
            colors: [Color(hex: "007AFF"), Color(hex: "FF6B9D")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        secondary: LinearGradient(
            colors: [Color(hex: "FF9500"), Color(hex: "FF6B9D")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        success: LinearGradient(
            colors: [Color(hex: "34C759"), Color(hex: "30D158")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    // Custom progress ring colors
    static let progressRings = ProgressRings(
        steps: Color(hex: "007AFF"),
        heartRate: Color(hex: "FF6B9D"),
        calories: Color(hex: "FF9500"),
        distance: Color(hex: "34C759")
    )
}

struct Gradients {
    let primary: LinearGradient
    let secondary: LinearGradient
    let success: LinearGradient
}

struct ProgressRings {
    let steps: Color
    let heartRate: Color
    let calories: Color
    let distance: Color
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
