//
//  ContentView.swift
//  Fitglide_Watch_App Watch App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import SwiftUI
import HealthKit
import WatchKit

struct ContentView: View {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var healthService = HealthService()
    @StateObject private var liveCheerManager = LiveCheerManager()
    @StateObject private var challengeManager = ChallengeManager()
    // Watch app works independently - no iPhone dependency required
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Activity Rings & Quick Stats
            HomeView()
                .tag(0)
            
            // Workout Tab - Start/Stop Workouts
            WorkoutView()
                .tag(1)
            
            // Activity Tab - Detailed Stats
            ActivityView()
                .tag(2)
            
            // Challenges Tab - Light Challenges
            ChallengesView()
                .tag(3)
            
            // Live Cheers Tab - Social Features
            LiveCheersView()
                .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .environmentObject(workoutManager)
        .environmentObject(healthService)
        .environmentObject(liveCheerManager)
        .environmentObject(challengeManager)
        // Watch app works independently - no iPhone dependency required
    }
}

// MARK: - Home View (Custom FitGlide Design)
struct HomeView: View {
    @EnvironmentObject var healthService: HealthService
    @State private var healthData = WatchHealthData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Header with gradient
                HStack {
                    Text("FitGlide")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                    // Live workout indicator
                    if healthData.isWorkoutActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(WatchTheme.gradients.success)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(WatchTheme.colors.surfaceVariant)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Custom Progress View
                ActivityRingsView(healthData: healthData)
                    .frame(height: 100)
                
                // Enhanced Quick Stats - Bigger rectangular cards
                VStack(spacing: 6) {
                    LargeStatCard(
                        title: "Steps",
                        value: "\(healthData.steps)",
                        icon: "figure.walk",
                        gradient: WatchTheme.gradients.primary,
                        progress: min(Double(healthData.steps) / 10000.0, 1.0)
                    )
                    
                    LargeStatCard(
                        title: "Heart Rate",
                        value: "\(healthData.heartRate)",
                        unit: " BPM",
                        icon: "heart.fill",
                        gradient: WatchTheme.gradients.secondary,
                        progress: min(Double(healthData.heartRate) / 200.0, 1.0)
                    )
                    
                    LargeStatCard(
                        title: "Calories",
                        value: "\(healthData.calories)",
                        unit: " cal",
                        icon: "flame.fill",
                        gradient: WatchTheme.gradients.secondary,
                        progress: min(Double(healthData.calories) / 500.0, 1.0)
                    )
                    
                    LargeStatCard(
                        title: "Distance",
                        value: String(format: "%.1f", healthData.distance),
                        unit: " km",
                        icon: "location.fill",
                        gradient: WatchTheme.gradients.success,
                        progress: min(healthData.distance / 10.0, 1.0)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            Task {
                await loadHealthData()
            }
        }
    }
    
    private func loadHealthData() async {
        healthData = await healthService.fetchTodayHealthData()
    }
}

// MARK: - Custom FitGlide Progress View (No Apple Health Rings)
struct ActivityRingsView: View {
    let healthData: WatchHealthData
    
    var body: some View {
        VStack(spacing: 12) {
            // Main progress indicator with gradient
            ZStack {
                // Background circle
                Circle()
                    .stroke(WatchTheme.colors.surfaceVariant.opacity(0.3), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                // Progress circle with gradient
                Circle()
                    .trim(from: 0, to: min(Double(healthData.steps) / 10000.0, 1.0))
                    .stroke(
                        WatchTheme.gradients.primary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: healthData.steps)
                
                // Center icon
                Image(systemName: "figure.walk")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(WatchTheme.colors.onBackground)
            }
            
            // Progress text
            VStack(spacing: 2) {
                Text("\(healthData.steps)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                Text("steps")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Enhanced Workout View
struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 16) {
            if workoutManager.isWorkoutActive {
                EnhancedActiveWorkoutView()
            } else {
                EnhancedInactiveWorkoutView()
            }
        }
        .padding()
    }
}

struct EnhancedActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @State private var showingLiveCheerSettings = false
    @State private var showingCheerNotification = false
    @State private var cheerNotificationText = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Enhanced workout status with gradient
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(WatchTheme.gradients.success)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(WatchTheme.colors.surfaceVariant)
                .cornerRadius(12)
                
                Spacer()
                
                // Live Cheer Status
                if liveCheerManager.isLiveCheerEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(WatchTheme.colors.secondary)
                        Text("\(liveCheerManager.cheerCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onBackground)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WatchTheme.gradients.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Share Live Workout button
                Button(action: {
                    showingLiveCheerSettings = true
                }) {
                    Image(systemName: liveCheerManager.isLiveCheerEnabled ? "heart.fill" : "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(liveCheerManager.isLiveCheerEnabled ? WatchTheme.colors.secondary : WatchTheme.colors.onBackground)
                }
            }
            
            // Workout type with gradient background
            Text(workoutManager.currentWorkoutType)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(WatchTheme.gradients.primary)
                .cornerRadius(16)
            
            // Enhanced duration display
            Text(formatDuration(workoutManager.workoutDuration))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(WatchTheme.colors.onBackground)
                .padding(.vertical, 4)
            
            // Enhanced metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                EnhancedMetricView(
                    value: "\(Int(workoutManager.heartRate))",
                    unit: "BPM",
                    label: "Heart Rate",
                    icon: "heart.fill",
                    gradient: WatchTheme.gradients.secondary
                )
                
                EnhancedMetricView(
                    value: "\(Int(workoutManager.calories))",
                    unit: "cal",
                    label: "Calories",
                    icon: "flame.fill",
                    gradient: WatchTheme.gradients.secondary
                )
            }
            
            // Enhanced controls
            HStack(spacing: 12) {
                Button("End") {
                    workoutManager.endWorkout()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .background(WatchTheme.gradients.primary)
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingLiveCheerSettings) {
            EnhancedLiveCheerSettingsView()
        }
        .overlay(
            // Cheer notification overlay
            Group {
                if showingCheerNotification {
                    CheerNotificationOverlay(text: cheerNotificationText)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingCheerNotification = false
                                }
                            }
                        }
                }
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: .cheerReceived)) { notification in
            if let cheerCount = notification.userInfo?["cheerCount"] as? Int {
                cheerNotificationText = "🎉 \(cheerCount) Cheers!"
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingCheerNotification = true
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct EnhancedInactiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    private let workoutTypes: [(HKWorkoutActivityType, String, String)] = [
        (.running, "figure.run", "Running"),
        (.walking, "figure.walk", "Walking"),
        (.cycling, "bicycle", "Cycling"),
        (.swimming, "figure.pool.swim", "Swimming"),
        (.yoga, "figure.mind.and.body", "Yoga"),
        (.functionalStrengthTraining, "dumbbell.fill", "Strength"),
        (.highIntensityIntervalTraining, "flame.fill", "HIIT"),
        (.mixedCardio, "heart.fill", "Cardio")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Choose Workout")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                    .padding(.bottom, 8)
                
                // Bigger rectangular cards stacked vertically
                VStack(spacing: 6) {
                    ForEach(workoutTypes, id: \.0) { workoutType in
                        LargeWorkoutCard(
                            icon: workoutType.1,
                            title: workoutType.2,
                            gradient: WatchTheme.gradients.primary
                        ) {
                            workoutManager.startWorkout(type: workoutType.0)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct LargeWorkoutCard: View {
    let icon: String
    let title: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with gradient background (matching main app style)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cheer Card Component
struct CheerCard: View {
    let cheer: CheerService.StrapiCheer
    
    var body: some View {
        HStack(spacing: 8) {
            // Sender avatar/icon
            ZStack {
                Circle()
                    .fill(WatchTheme.gradients.primary)
                    .frame(width: 24, height: 24)
                
                Text(String(cheer.sender.firstName?.prefix(1) ?? cheer.sender.username?.prefix(1) ?? "U"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cheer.sender.firstName ?? cheer.sender.username ?? "Unknown")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                
                Text(cheer.message)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time ago
            Text(timeAgo(from: cheer.createdAt))
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func timeAgo(from dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return "Unknown"
        }
        
        let timeInterval = Date().timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Enhanced Activity View
struct ActivityView: View {
    @EnvironmentObject var healthService: HealthService
    @State private var healthData = WatchHealthData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Enhanced header
                HStack {
                    Text("Today's Activity")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Enhanced detailed stats
                VStack(spacing: 6) {
                    EnhancedDetailStatRow(
                        title: "Steps",
                        value: "\(healthData.steps)",
                        goal: "10,000",
                        icon: "figure.walk",
                        gradient: WatchTheme.gradients.primary
                    )
                    
                    EnhancedDetailStatRow(
                        title: "Heart Rate",
                        value: "\(healthData.heartRate)",
                        unit: " BPM",
                        goal: "60-100",
                        icon: "heart.fill",
                        gradient: WatchTheme.gradients.secondary
                    )
                    
                    EnhancedDetailStatRow(
                        title: "Calories",
                        value: "\(healthData.calories)",
                        unit: " cal",
                        goal: "500",
                        icon: "flame.fill",
                        gradient: WatchTheme.gradients.secondary
                    )
                    
                    EnhancedDetailStatRow(
                        title: "Distance",
                        value: String(format: "%.1f", healthData.distance),
                        unit: " km",
                        goal: "5.0",
                        icon: "location.fill",
                        gradient: WatchTheme.gradients.success
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            Task {
                await loadHealthData()
            }
        }
    }
    
    private func loadHealthData() async {
        healthData = await healthService.fetchTodayHealthData()
    }
}

// MARK: - Enhanced Supporting Views
struct LargeStatCard: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    let gradient: LinearGradient
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with gradient background (matching main app style)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Title
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                
                // Value with unit
                Text(value + unit)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(WatchTheme.colors.surfaceVariant.opacity(0.3))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(gradient)
                            .frame(width: geometry.size.width * progress, height: 3)
                            .animation(.easeInOut(duration: 1.0), value: progress)
                    }
                }
                .frame(width: 30, height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
        .cornerRadius(16)
    }
}

struct EnhancedMetricView: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon with gradient background (matching main app style)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(gradient)
                    .frame(width: 20, height: 20)
                
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(value + unit)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(WatchTheme.colors.onBackground)
            
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
        .cornerRadius(8)
    }
}

struct EnhancedDetailStatRow: View {
    let title: String
    let value: String
    var unit: String = ""
    let goal: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon with gradient background (matching main app style)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(gradient)
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onBackground)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value + unit)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                
                Text(goal)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - Enhanced Live Cheer Settings View
struct EnhancedLiveCheerSettingsView: View {
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Live Cheers")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                }
                .padding(.horizontal)
                
                // Enable/Disable Toggle
                VStack(spacing: 8) {
                    HStack {
                        Text("Share Live Workout")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onBackground)
                        Spacer()
                        Toggle("", isOn: $liveCheerManager.isLiveCheerEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: WatchTheme.colors.primary))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
                    .cornerRadius(12)
                    
                    if liveCheerManager.isLiveCheerEnabled {
                        Text("Your friends can cheer you on during workouts!")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                // Cheer Count
                if liveCheerManager.isLiveCheerEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(WatchTheme.colors.secondary)
                            Text("Cheers Received")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                            Text("\(liveCheerManager.cheerCount)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WatchTheme.gradients.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Friends Section
                if liveCheerManager.isLiveCheerEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Friends")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if liveCheerManager.selectedFriends.isEmpty {
                            Text("No friends selected")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(liveCheerManager.selectedFriends, id: \.self) { friendId in
                                    HStack {
                                        Text("Friend \(friendId)")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(WatchTheme.colors.onBackground)
                                        Spacer()
                                        Button("Remove") {
                                            liveCheerManager.removeFriend(friendId)
                                        }
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button("Add Friends") {
                            // Will be implemented when we connect to Strapi friends data
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(WatchTheme.gradients.primary)
                        .cornerRadius(8)
                    }
                }
                
                // Packs Section
                if liveCheerManager.isLiveCheerEnabled {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Packs")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if liveCheerManager.selectedPacks.isEmpty {
                            Text("No packs selected")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 4) {
                                ForEach(liveCheerManager.selectedPacks, id: \.self) { packId in
                                    HStack {
                                        Text("Pack \(packId)")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(WatchTheme.colors.onBackground)
                                        Spacer()
                                        Button("Remove") {
                                            liveCheerManager.removePack(packId)
                                        }
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button("Add Packs") {
                            // Will be implemented when we connect to Strapi packs data
                        }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(WatchTheme.gradients.success)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Cheer Notification Overlay
struct CheerNotificationOverlay: View {
    let text: String
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(WatchTheme.colors.secondary)
                
                Text(text)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(WatchTheme.gradients.secondary.opacity(0.9))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Live Cheers View
struct LiveCheersView: View {
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @EnvironmentObject var workoutManager: WorkoutManager
    // Watch app works independently - no iPhone dependency required
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Live Cheers")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    
                    Spacer()
                    
                    // Standalone indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(WatchTheme.colors.primary)
                            .frame(width: 6, height: 6)
                        Text("Standalone")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                    }
                }
                .padding(.horizontal)
                
                // Status Card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: liveCheerManager.isLiveCheerEnabled ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(liveCheerManager.isLiveCheerEnabled ? WatchTheme.colors.secondary : WatchTheme.colors.onSurfaceVariant)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(liveCheerManager.isLiveCheerEnabled ? "Live Cheers Active" : "Live Cheers Disabled")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            
                            Text(liveCheerManager.isLiveCheerEnabled ? "Friends can cheer you on!" : "Enable to share workouts")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
                    .cornerRadius(12)
                    
                    // Cheer Count
                    if liveCheerManager.isLiveCheerEnabled {
                        HStack {
                            Text("Total Cheers Received")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                            if liveCheerManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("\(liveCheerManager.cheerCount)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(WatchTheme.colors.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WatchTheme.gradients.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Refresh Button
                        Button(action: {
                            Task {
                                await liveCheerManager.loadCheersFromStrapi()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                Text("Refresh")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(WatchTheme.colors.secondary)
                        }
                        .buttonStyle(.bordered)
                        .tint(WatchTheme.colors.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Recent Cheers
                VStack(spacing: 8) {
                    HStack {
                        Text("Recent Cheers")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onBackground)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if liveCheerManager.receivedCheers.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "heart")
                                .font(.system(size: 16))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                            Text("No Cheers Yet")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                            Text("Start a workout to receive cheers")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(liveCheerManager.receivedCheers.prefix(3), id: \.id) { cheer in
                                CheerCard(cheer: cheer)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Quick Actions
                VStack(spacing: 8) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 14))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Text("Settings")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Quick Start Workout Button
                    if !workoutManager.isWorkoutActive {
                        Button(action: {
                            // Navigate to workout tab
                            // This will be handled by the parent view
                        }) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Text("Start Workout")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(WatchTheme.gradients.primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Show active workout status
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(WatchTheme.colors.secondary)
                            Text("Workout Active")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                            Text("\(liveCheerManager.cheerCount)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(WatchTheme.gradients.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Info Section
                VStack(spacing: 8) {
                    Text("How it works:")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Enable Live Cheers in Settings")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                        
                        Text("2. Select friends and packs")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                        
                        Text("3. Start a workout to share")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                        
                        Text("4. Receive cheers in real-time!")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(WatchTheme.colors.surfaceVariant.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingSettings) {
            EnhancedLiveCheerSettingsView()
        }
    }
}

// MARK: - Challenges View
struct ChallengesView: View {
    @EnvironmentObject var challengeManager: ChallengeManager
    @EnvironmentObject var healthService: HealthService
    @State private var healthData = WatchHealthData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Challenges")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                    
                    // Refresh button
                    Button(action: {
                        Task {
                            await challengeManager.loadChallengesFromStrapi()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(WatchTheme.colors.onBackground)
                    }
                }
                .padding(.horizontal)
                
                // Loading State
                if challengeManager.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading challenges...")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                    }
                    .padding(.vertical, 20)
                }
                
                // Error State
                else if let errorMessage = challengeManager.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16))
                            .foregroundColor(WatchTheme.colors.tertiary)
                        Text(errorMessage)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(WatchTheme.colors.tertiary.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Active Challenges
                else {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Active")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.colors.onBackground)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        let activeChallenges = challengeManager.getActiveChallenges()
                        if activeChallenges.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 16))
                                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                Text("No Challenges Available")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                Text("Check back later for new challenges")
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(activeChallenges) { challenge in
                                    ChallengeCard(challenge: challenge)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Completed Challenges
                VStack(spacing: 8) {
                    HStack {
                        Text("Completed")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onBackground)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    let completedChallenges = challengeManager.getCompletedChallenges()
                    if completedChallenges.isEmpty {
                        Text("No completed challenges")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(completedChallenges.prefix(3)) { challenge in
                                CompletedChallengeCard(challenge: challenge)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            Task {
                await loadHealthData()
                updateChallengeProgress()
            }
        }
    }
    
    private func loadHealthData() async {
        healthData = await healthService.fetchTodayHealthData()
    }
    
    private func updateChallengeProgress() {
        // Update challenge progress with current health data
        challengeManager.updateChallengeProgress(type: .dailySteps, value: Double(healthData.steps))
        challengeManager.updateChallengeProgress(type: .dailyCalories, value: Double(healthData.calories))
        
        // TODO: Update weekly and monthly challenges when we have more data
    }
}

// MARK: - Challenge Card
struct ChallengeCard: View {
    let challenge: ChallengeManager.Challenge
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(WatchTheme.gradients.primary)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    
                    Text("\(Int(challenge.currentValue))/\(Int(challenge.target)) \(challenge.type.unit)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(challenge.progressPercentage)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.primary)
                    
                    Text(challenge.timeRemaining)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(WatchTheme.colors.surfaceVariant.opacity(0.3))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(WatchTheme.gradients.primary)
                        .frame(width: geometry.size.width * challenge.progress, height: 3)
                        .animation(.easeInOut(duration: 1.0), value: challenge.progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Completed Challenge Card
struct CompletedChallengeCard: View {
    let challenge: ChallengeManager.Challenge
    
    var body: some View {
        HStack {
            // Icon with success color
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(WatchTheme.gradients.success)
                    .frame(width: 20, height: 20)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                
                if let completedDate = challenge.completedDate {
                    Text("Completed \(formatDate(completedDate))")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onSurfaceVariant)
                }
            }
            
            Spacer()
            
            Text("100%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(WatchTheme.colors.quaternary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(WatchTheme.gradients.success.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
        .environmentObject(HealthService())
        .environmentObject(LiveCheerManager())
        .environmentObject(ChallengeManager())
}
