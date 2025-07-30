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
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .environmentObject(workoutManager)
        .environmentObject(healthService)
    }
}

// MARK: - Home View (Activity Rings)
struct HomeView: View {
    @EnvironmentObject var healthService: HealthService
    @State private var healthData = WatchHealthData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App Header
                HStack {
                    Text("FitGlide")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(WatchTheme.colors.primary)
                        .font(.system(size: 16))
                }
                .padding(.horizontal)
                
                // Activity Rings (like Apple Fitness)
                ActivityRingsView(healthData: healthData)
                    .frame(height: 120)
                
                // Quick Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                                    QuickStatCard(
                    title: "Steps",
                    value: "\(healthData.steps)",
                    icon: "figure.walk",
                    color: WatchTheme.colors.quaternary
                )
                
                QuickStatCard(
                    title: "Heart Rate",
                    value: "\(healthData.heartRate)",
                    unit: " BPM",
                    icon: "heart.fill",
                    color: WatchTheme.colors.primary
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: "\(healthData.calories)",
                    unit: " cal",
                    icon: "flame.fill",
                    color: WatchTheme.colors.tertiary
                )
                    
                    QuickStatCard(
                        title: "Distance",
                        value: String(format: "%.1f", healthData.distance),
                        unit: " km",
                        icon: "location.fill",
                        color: .blue
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

// MARK: - Activity Rings View
struct ActivityRingsView: View {
    let healthData: WatchHealthData
    
    var body: some View {
        ZStack {
            // Outer ring (Steps)
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 8)
                .frame(width: 100, height: 100)
            
            Circle()
                .trim(from: 0, to: min(Double(healthData.steps) / 10000.0, 1.0))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: healthData.steps)
            
            // Middle ring (Heart Rate)
            Circle()
                .stroke(Color.red.opacity(0.3), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: min(Double(healthData.heartRate) / 200.0, 1.0))
                .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: healthData.heartRate)
            
            // Inner ring (Calories)
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 8)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: min(Double(healthData.calories) / 500.0, 1.0))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: healthData.calories)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(healthData.steps)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                Text("steps")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Workout View
struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingWorkoutPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            if workoutManager.isWorkoutActive {
                ActiveWorkoutView()
            } else {
                InactiveWorkoutView(showingWorkoutPicker: $showingWorkoutPicker)
            }
        }
        .padding()
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerView()
        }
    }
}

struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Workout status
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text("ACTIVE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Spacer()
            }
            
            // Workout type
            Text(workoutManager.currentWorkoutType)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Duration
            Text(formatDuration(workoutManager.workoutDuration))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            // Metrics
            HStack(spacing: 20) {
                MetricView(
                    value: "\(Int(workoutManager.heartRate))",
                    unit: "BPM",
                    label: "Heart Rate"
                )
                
                MetricView(
                    value: "\(Int(workoutManager.calories))",
                    unit: "cal",
                    label: "Calories"
                )
            }
            
            // Controls
            HStack(spacing: 16) {
                Button("End") {
                    workoutManager.endWorkout()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct InactiveWorkoutView: View {
    @Binding var showingWorkoutPicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Start Workout")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(WatchTheme.colors.onPrimary)
            
            Button("Choose Activity") {
                showingWorkoutPicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

// MARK: - Activity View
struct ActivityView: View {
    @EnvironmentObject var healthService: HealthService
    @State private var healthData = WatchHealthData()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Today's Activity")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(WatchTheme.colors.onBackground)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Detailed stats
                VStack(spacing: 8) {
                    DetailStatRow(
                        title: "Steps",
                        value: "\(healthData.steps)",
                        goal: "10,000",
                        icon: "figure.walk",
                        color: WatchTheme.colors.quaternary
                    )
                    
                    DetailStatRow(
                        title: "Heart Rate",
                        value: "\(healthData.heartRate)",
                        unit: " BPM",
                        goal: "60-100",
                        icon: "heart.fill",
                        color: WatchTheme.colors.primary
                    )
                    
                    DetailStatRow(
                        title: "Calories",
                        value: "\(healthData.calories)",
                        unit: " cal",
                        goal: "500",
                        icon: "flame.fill",
                        color: WatchTheme.colors.tertiary
                    )
                    
                    DetailStatRow(
                        title: "Distance",
                        value: String(format: "%.1f", healthData.distance),
                        unit: " km",
                        goal: "5.0",
                        icon: "location.fill",
                        color: WatchTheme.colors.secondary
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

// MARK: - Supporting Views
struct QuickStatCard: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value + unit)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(WatchTheme.colors.onBackground)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.3))
        .cornerRadius(8)
    }
}

struct MetricView: View {
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value + unit)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(WatchTheme.colors.onBackground)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onSurfaceVariant)
        }
    }
}

struct DetailStatRow: View {
    let title: String
    let value: String
    var unit: String = ""
    let goal: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(WatchTheme.colors.onBackground)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value + unit)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onBackground)
                
                Text(goal)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(WatchTheme.colors.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(WatchTheme.colors.surfaceVariant.opacity(0.3))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutManager())
        .environmentObject(HealthService())
}
