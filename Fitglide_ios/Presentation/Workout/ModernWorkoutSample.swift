//
//  ModernWorkoutSample.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct ModernWorkoutSample: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animateContent = false
    @State private var showMotivationalQuote = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        theme.background,
                        theme.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header
                        ModernHeaderSection(theme: theme, animateContent: $animateContent)
                        
                        // Motivational Quote
                        if showMotivationalQuote {
                            SampleMotivationalQuoteCard(theme: theme)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Enhanced Steps Card
                        ModernStepsCard(theme: theme, animateContent: $animateContent)
                        
                        // Metrics Grid
                        ModernMetricsGrid(theme: theme, animateContent: $animateContent)
                        
                        // Current Workout Card
                        ModernCurrentWorkoutCard(theme: theme, animateContent: $animateContent)
                        
                        // Quick Actions
                        ModernQuickActionsGrid(theme: theme, animateContent: $animateContent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
        }
    }
}

// MARK: - Modern Header Section
struct ModernHeaderSection: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Ready to crush it today?")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.onSurface)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
            }
            
            // Date Selector
            SampleModernDateSelector(theme: theme, animateContent: $animateContent)
        }
        .padding(.top, 8)
        .background(
            theme.background
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Sample Modern Date Selector
struct SampleModernDateSelector: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    @State private var selectedDate = Date()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
                    
                    Button(action: { selectedDate = date }) {
                        VStack(spacing: 4) {
                            Text(dayOfWeek(for: date))
                                .font(FitGlideTheme.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? theme.onPrimary : theme.onSurfaceVariant)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? theme.onPrimary : theme.onSurface)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? theme.primary : (isToday ? theme.primary.opacity(0.1) : theme.surface))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday && !isSelected ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(offset + 3) * 0.05), value: animateContent)
                }
            }
        }
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Motivational Quote Card
struct SampleMotivationalQuoteCard: View {
    let theme: FitGlideTheme.Colors
    
    private let quotes = [
        "The only bad workout is the one that didn't happen.",
        "Your body can stand almost anything. It's your mind you have to convince.",
        "Strength does not come from the physical capacity. It comes from an indomitable will.",
        "The difference between try and triumph is just a little umph!",
        "Make yourself proud."
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                Text("Daily Motivation")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(quotes.randomElement() ?? quotes[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Modern Steps Card
struct ModernStepsCard: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    private let steps = 8247
    private let goal = 10000
    private var progress: Double {
        min(Double(steps) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Steps Today")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Keep moving, keep growing")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(steps)")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primary)
                    
                    Text("of \(goal)")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.surfaceVariant)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: UIScreen.main.bounds.width * 0.8 * progress, height: 8)
                    .scaleEffect(x: animateContent ? 1.0 : 0.0, anchor: .leading)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
}

// MARK: - Modern Metrics Grid
struct ModernMetricsGrid: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            SampleModernMetricCard(
                title: "Heart Rate",
                value: "72",
                unit: "bpm",
                icon: "heart.fill",
                color: .red,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.2
            )
            
            SampleModernMetricCard(
                title: "Calories",
                value: "1,247",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.3
            )
            
            SampleModernMetricCard(
                title: "Stress",
                value: "23",
                unit: "%",
                icon: "brain.head.profile",
                color: .purple,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.4
            )
        }
    }
}

// MARK: - Sample Modern Metric Card
struct SampleModernMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Modern Current Workout Card
struct ModernCurrentWorkoutCard: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Workout")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Keep going, you're doing great!")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Continue")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            
            // Workout progress
            VStack(spacing: 8) {
                HStack {
                    Text("Strength Training")
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("3/5")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                ProgressView(value: 0.6)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
}

// MARK: - Modern Quick Actions Grid
struct ModernQuickActionsGrid: View {
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                SampleModernQuickActionButton(
                    title: "Create Workout",
                    icon: "plus.circle.fill",
                    color: theme.primary,
                    action: {},
                    theme: theme,
                    animateContent: $animateContent,
                    delay: 0.8
                )
                
                SampleModernQuickActionButton(
                    title: "Browse Plans",
                    icon: "list.bullet",
                    color: .blue,
                    action: {},
                    theme: theme,
                    animateContent: $animateContent,
                    delay: 0.9
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
}

// MARK: - Sample Modern Quick Action Button
struct SampleModernQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

#Preview {
    ModernWorkoutSample()
} 