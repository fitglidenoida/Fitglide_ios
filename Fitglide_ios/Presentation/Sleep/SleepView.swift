//
//  SleepView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 14/06/25.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var viewModel: SleepViewModel
    @State private var selectedDate = Date()
    @State private var showDetails = false
    @State private var showSettings = false
    @State private var showDatePicker = false
    @State private var animateContent = false
    @State private var showSleepWisdom = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Modern Header Section
                        modernHeaderSection
                        
                        // Indian Sleep Wisdom
                        if showSleepWisdom {
                            indianSleepWisdomCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Sleep Score Overview
                        sleepScoreOverview
                        
                        // Sleep Metrics Grid
                        sleepMetricsGrid
                        
                        // Sleep Quality Insights
                        sleepQualityInsights
                        
                        // Meditation & Relaxation
                        meditationRelaxationSection
                        
                        // Sleep Schedule
                        sleepScheduleSection
                        
                        // Quick Actions
                        modernQuickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show sleep wisdom after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSleepWisdom = true
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SleepSettingsView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep & Wellness 😴")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Rest well, live well")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showSettings = true }) {
                                ZStack {
                        Circle()
                            .fill(FitGlideTheme.colors(for: colorScheme).surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Date Selector
            modernDateSelector
        }
        .padding(.bottom, 16)
        .background(
            FitGlideTheme.colors(for: colorScheme).background
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Modern Date Selector
    var modernDateSelector: some View {
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
                                .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).onPrimary : FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? FitGlideTheme.colors(for: colorScheme).onPrimary : FitGlideTheme.colors(for: colorScheme).onSurface)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? FitGlideTheme.colors(for: colorScheme).primary : (isToday ? FitGlideTheme.colors(for: colorScheme).primary.opacity(0.1) : FitGlideTheme.colors(for: colorScheme).surface))
                        )
                                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday && !isSelected ? FitGlideTheme.colors(for: colorScheme).primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(offset + 3) * 0.05), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Indian Sleep Wisdom Card
    var indianSleepWisdomCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                
                Spacer()
                
                Text("Sleep Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
            }
            
            Text(indianSleepWisdom.randomElement() ?? indianSleepWisdom[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitGlideTheme.colors(for: colorScheme).surface)
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Sleep Score Overview
    var sleepScoreOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Score")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                            if let sleepData = viewModel.sleepData {
                    Text("\(sleepData.score)/100")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                }
            }
            
            // Sleep Score Circle
                            if let sleepData = viewModel.sleepData {
                                ZStack {
                    Circle()
                        .stroke(FitGlideTheme.colors(for: colorScheme).surfaceVariant, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(sleepData.score) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [FitGlideTheme.colors(for: colorScheme).primary, FitGlideTheme.colors(for: colorScheme).secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                    
                    VStack(spacing: 2) {
                        Text("\(sleepData.score)")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                        
                        Text("Score")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurfaceVariant)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitGlideTheme.colors(for: colorScheme).surface)
                .shadow(color: FitGlideTheme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
        .onTapGesture {
            showDetails = true
        }
    }
    
    // MARK: - Sleep Metrics Grid
    var sleepMetricsGrid: some View {
        HStack(spacing: 12) {
            ModernSleepMetricCard(
                title: "Sleep Time",
                value: sleepTimeText,
                unit: "hours",
                icon: "moon.fill",
                color: .purple,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.2
            )
            
            ModernSleepMetricCard(
                title: "Sleep Debt",
                value: viewModel.sleepData?.debt ?? "0",
                unit: "hours",
                icon: "clock.fill",
                color: .orange,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.3
            )
            
            ModernSleepMetricCard(
                title: "Deep Sleep",
                value: "\(Int((viewModel.sleepData?.actualSleepTime ?? 0) * 0.25))",
                unit: "hours",
                icon: "brain.head.profile",
                color: .blue,
                theme: FitGlideTheme.colors(for: colorScheme),
                animateContent: $animateContent,
                delay: 0.4
            )
        }
    }
    
    // MARK: - Sleep Quality Insights
    var sleepQualityInsights: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Quality Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                SleepQualityInsightCard(
                    title: "Sleep Efficiency",
                    value: "\(Int((viewModel.sleepData?.actualSleepTime ?? 0) / (viewModel.sleepData?.restTime ?? 1) * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.5
                )
                
                SleepQualityInsightCard(
                    title: "Sleep Consistency",
                    value: "Good",
                    icon: "calendar",
                    color: .blue,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.6
                )
                
                SleepQualityInsightCard(
                    title: "Recovery Score",
                    value: "\(viewModel.sleepData?.score ?? 0)/100",
                    icon: "heart.fill",
                    color: .red,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.7
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Meditation & Relaxation Section
    var meditationRelaxationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Meditation & Relaxation")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                Button("View All") {
                    // Show all meditation content
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indianMeditationPractices, id: \.self) { practice in
                        IndianMeditationCard(
                            title: practice.title,
                            duration: practice.duration,
                            icon: practice.icon,
                            color: practice.color,
                            theme: FitGlideTheme.colors(for: colorScheme),
                            animateContent: $animateContent,
                            delay: 0.8 + Double(indianMeditationPractices.firstIndex(of: practice) ?? 0) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
    
    // MARK: - Sleep Schedule Section
    var sleepScheduleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Schedule")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SleepScheduleCard(
                    title: "Bedtime",
                    time: "10:30 PM",
                    icon: "bed.double.fill",
                    color: .purple,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.9
                )
                
                SleepScheduleCard(
                    title: "Wake Time",
                    time: "6:30 AM",
                    icon: "sunrise.fill",
                    color: .orange,
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.0
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
    }
    
    // MARK: - Modern Quick Actions Section
    var modernQuickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(FitGlideTheme.colors(for: colorScheme).onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ModernSleepQuickActionButton(
                    title: "Start Meditation",
                    icon: "brain.head.profile",
                    color: FitGlideTheme.colors(for: colorScheme).primary,
                    action: { /* Start meditation */ },
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.1
                )
                
                ModernSleepQuickActionButton(
                    title: "Sleep Timer",
                    icon: "timer",
                    color: .blue,
                    action: { /* Set sleep timer */ },
                    theme: FitGlideTheme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.2
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.1), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var sleepTimeText: String {
        if let sleepData = viewModel.sleepData {
            return String(format: "%.1f", sleepData.actualSleepTime)
        }
        return "0.0"
    }
    
    private var indianSleepWisdom: [String] {
        [
            "Early to bed and early to rise makes a person healthy, wealthy, and wise.",
            "Sleep is the best meditation - Dalai Lama",
            "A good night's sleep is the foundation of a productive day.",
            "Your body heals and repairs while you sleep peacefully.",
            "Quality sleep is the key to mental and physical wellness."
        ]
    }
    
    private var indianMeditationPractices: [IndianMeditationPractice] {
        [
            IndianMeditationPractice(title: "Pranayama", duration: "10 min", icon: "lungs.fill", color: .blue),
            IndianMeditationPractice(title: "Yoga Nidra", duration: "20 min", icon: "moon.stars.fill", color: .purple),
            IndianMeditationPractice(title: "Mindfulness", duration: "15 min", icon: "brain.head.profile", color: .green),
            IndianMeditationPractice(title: "Deep Breathing", duration: "5 min", icon: "wind", color: .cyan)
        ]
    }

    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Modern Sleep Metric Card
struct ModernSleepMetricCard: View {
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

// MARK: - Sleep Quality Insight Card
struct SleepQualityInsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Indian Meditation Card
struct IndianMeditationCard: View {
    let title: String
    let duration: String
    let icon: String
        let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Text(duration)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text(title)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
        }
        .padding(16)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Sleep Schedule Card
struct SleepScheduleCard: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double

        var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(time)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
            }
            
            Spacer()
            
            Button("Edit") {
                // Edit schedule
            }
            .font(FitGlideTheme.caption)
            .foregroundColor(theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Modern Sleep Quick Action Button
struct ModernSleepQuickActionButton: View {
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

// MARK: - Supporting Data Structures
struct IndianMeditationPractice: Hashable {
    let title: String
    let duration: String
    let icon: String
    let color: Color
}
