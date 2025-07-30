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
    
    // Watch app uses dark theme by default for better visibility
    static let colors = Colors(
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