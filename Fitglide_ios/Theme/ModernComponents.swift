//
//  ModernComponents.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowColor: Color
    let backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        padding: CGFloat = FitGlideTheme.Spacing.medium,
        cornerRadius: CGFloat = FitGlideTheme.Card.cornerRadius,
        shadowRadius: CGFloat = FitGlideTheme.Card.elevation,
        shadowColor: Color = Color.black.opacity(0.1),
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.backgroundColor = backgroundColor ?? Color.white // Default to white, will be overridden in body
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor == Color.white ? FitGlideTheme.colors(for: colorScheme).surface : backgroundColor)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
            )
    }
}

// MARK: - Modern Button Component
struct ModernButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        
        var backgroundColor: Color {
            let colors = FitGlideTheme.colors(for: .light) // We'll handle dark mode in the button
            switch self {
            case .primary: return colors.primary
            case .secondary: return colors.secondary
            case .tertiary: return colors.surfaceVariant
            case .destructive: return Color.red
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary, .destructive: return .white
            case .tertiary: return FitGlideTheme.colors(for: .light).onSurface
            }
        }
    }
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FitGlideTheme.Spacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, FitGlideTheme.Button.padding)
            .padding(.vertical, FitGlideTheme.Button.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius)
                    .fill(style.backgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(FitGlideTheme.Animation.quick, value: true)
    }
}

// MARK: - Modern Progress Bar
struct ModernProgressBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let backgroundColor: Color
    let height: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        value: Double,
        maxValue: Double = 1.0,
        color: Color? = nil,
        backgroundColor: Color? = nil,
        height: CGFloat = 8
    ) {
        self.value = value
        self.maxValue = maxValue
        self.color = color ?? Color.blue // Default to blue, will be overridden in body
        self.backgroundColor = backgroundColor ?? Color.gray // Default to gray, will be overridden in body
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor == Color.gray ? FitGlideTheme.colors(for: colorScheme).surfaceVariant : backgroundColor)
                
                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color == Color.blue ? FitGlideTheme.colors(for: colorScheme).primary : color)
                    .frame(width: geometry.size.width * CGFloat(value / maxValue))
                    .animation(FitGlideTheme.Animation.easeInOut, value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Modern Badge
struct ModernBadge: View {
    let text: String
    let color: Color
    let backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        text: String,
        color: Color? = nil,
        backgroundColor: Color? = nil
    ) {
        self.text = text
        self.color = color ?? Color.white // Default to white, will be overridden in body
        self.backgroundColor = backgroundColor ?? Color.blue // Default to blue, will be overridden in body
    }
    
    var body: some View {
        Text(text)
            .font(FitGlideTheme.caption)
            .fontWeight(.semibold)
            .foregroundColor(color == Color.white ? FitGlideTheme.colors(for: colorScheme).onPrimary : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(backgroundColor == Color.blue ? FitGlideTheme.colors(for: colorScheme).primary : backgroundColor)
            )
    }
}

// MARK: - Modern Icon Button
struct ModernIconButton: View {
    let icon: String
    let color: Color
    let backgroundColor: Color
    let size: CGFloat
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String,
        color: Color? = nil,
        backgroundColor: Color? = nil,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color ?? Color.black // Default to black, will be overridden in body
        self.backgroundColor = backgroundColor ?? Color.gray // Default to gray, will be overridden in body
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color == Color.black ? FitGlideTheme.colors(for: colorScheme).onSurface : color)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor == Color.gray ? FitGlideTheme.colors(for: colorScheme).surfaceVariant : backgroundColor)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(FitGlideTheme.Animation.quick, value: true)
    }
}

// MARK: - Modern Divider
struct ModernDivider: View {
    let color: Color
    let height: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        color: Color? = nil,
        height: CGFloat = 1
    ) {
        self.color = color ?? Color.gray // Default to gray, will be overridden in body
        self.height = height
    }
    
    var body: some View {
        Rectangle()
            .fill(color == Color.gray ? FitGlideTheme.colors(for: colorScheme).surfaceVariant : color)
            .frame(height: height)
    }
}

// MARK: - Modern Loading Indicator
struct ModernLoadingIndicator: View {
    let text: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        text: String = "Loading...",
        color: Color? = nil
    ) {
        self.text = text
        self.color = color ?? Color.blue // Default to blue, will be overridden in body
    }
    
    var body: some View {
        VStack(spacing: FitGlideTheme.Spacing.medium) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: color == Color.blue ? FitGlideTheme.colors(for: colorScheme).primary : color))
                .scaleEffect(1.2)
            
            Text(text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
        }
        .padding(FitGlideTheme.Spacing.large)
    }
}

// MARK: - Modern Empty State
struct ModernEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: FitGlideTheme.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            
            VStack(spacing: FitGlideTheme.Spacing.small) {
                Text(title)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                ModernButton(title: actionTitle, style: .primary, action: action)
            }
        }
        .padding(FitGlideTheme.Spacing.extraLarge)
    }
} 