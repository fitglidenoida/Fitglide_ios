//
//  WorkoutSummaryView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import SwiftUI
import MapKit
import UIKit

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: HomeViewModel
    
    let workoutData: ActiveWorkoutData
    let workoutType: WorkoutType
    
    @State private var showWorkoutShare = false
    @State private var animateContent = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
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
                        // Header Section
                        workoutSummaryHeader
                        
                        // Achievement Section
                        achievementSection
                        
                        // Stats Overview
                        statsOverviewSection
                        
                        // Detailed Metrics
                        detailedMetricsSection
                        
                        // Laps Section (if any)
                        if !workoutData.laps.isEmpty {
                            lapsSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showWorkoutShare = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
            .sheet(isPresented: $showWorkoutShare) {
                // Simple sharing for manual workout
                ShareSheet(activityItems: [
                    "Just completed a \(workoutType.displayName) workout!",
                    "Duration: \(formatDuration(workoutData.duration))",
                    "Distance: \(formatDistance(workoutData.distance))",
                    "Calories: \(Int(workoutData.calories)) kcal"
                ])
            }
        }
    }
    
    // MARK: - Header Section
    private var workoutSummaryHeader: some View {
        VStack(spacing: 16) {
            // Workout Type Icon
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: workoutType.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(colors.primary)
            }
            .scaleEffect(animateContent ? 1.0 : 0.8)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
            
            VStack(spacing: 4) {
                Text("Workout Complete!")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text(workoutType.displayName)
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Achievement Section
    private var achievementSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Achievements")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            // Achievement badges
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                AchievementBadge(
                    title: "Distance",
                    value: formatDistance(workoutData.distance),
                    icon: "figure.walk",
                    color: .blue,
                    colors: colors,
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                AchievementBadge(
                    title: "Duration",
                    value: formatDuration(workoutData.duration),
                    icon: "clock.fill",
                    color: .green,
                    colors: colors,
                    animateContent: $animateContent,
                    delay: 0.4
                )
                
                AchievementBadge(
                    title: "Calories",
                    value: "\(Int(workoutData.calories))",
                    icon: "flame.fill",
                    color: .orange,
                    colors: colors,
                    animateContent: $animateContent,
                    delay: 0.5
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Stats Overview
    private var statsOverviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                StatCard(
                    title: "Average Pace",
                    value: calculatePace(),
                    icon: "speedometer",
                    color: .purple,
                    colors: colors,
                    animateContent: $animateContent,
                    delay: 0.6
                )
                
                StatCard(
                    title: "Heart Rate",
                    value: workoutData.heartRate > 0 ? "\(Int(workoutData.heartRate)) bpm" : "N/A",
                    icon: "heart.fill",
                    color: .red,
                    colors: colors,
                    animateContent: $animateContent,
                    delay: 0.7
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Detailed Metrics
    private var detailedMetricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Detailed Metrics")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                MetricRow(
                    label: "Total Distance",
                    value: formatDistance(workoutData.distance)
                )
                
                MetricRow(
                    label: "Total Duration",
                    value: formatDuration(workoutData.duration)
                )
                
                MetricRow(
                    label: "Calories Burned",
                    value: "\(Int(workoutData.calories)) kcal"
                )
                
                MetricRow(
                    label: "Average Heart Rate",
                    value: workoutData.heartRate > 0 ? "\(Int(workoutData.heartRate)) bpm" : "N/A"
                )
                
                MetricRow(
                    label: "Number of Laps",
                    value: "\(workoutData.laps.count)"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Laps Section
    private var lapsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Lap Times")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(Array(workoutData.laps.enumerated()), id: \.offset) { index, lap in
                    LapRow(
                        lapNumber: lap.number,
                        duration: formatDuration(lap.duration),
                        distance: formatDistance(lap.distance),
                        pace: formatPace(lap.pace),
                        colors: colors
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    color: colors.primary,
                    action: { showWorkoutShare = true },
                    theme: colors
                )
                
                QuickActionButton(
                    title: "Save",
                    icon: "bookmark",
                    color: .blue,
                    action: { saveWorkout() },
                    theme: colors
                )
                
                QuickActionButton(
                    title: "Done",
                    icon: "checkmark",
                    color: .green,
                    action: { dismiss() },
                    theme: colors
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        if pace > 0 {
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            return String(format: "%d:%02d /km", minutes, seconds)
        } else {
            return "--:-- /km"
        }
    }
    
    private func calculatePace() -> String {
        guard workoutData.distance > 0 else { return "--:-- /km" }
        let pace = workoutData.duration / (workoutData.distance / 1000)
        return formatPace(pace)
    }
    
    private func saveWorkout() {
        // Save workout to favorites or create a template
        // This would integrate with the existing workout system
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let colors: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let colors: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}



// MARK: - Lap Row
struct LapRow: View {
    let lapNumber: Int
    let duration: String
    let distance: String
    let pace: String
    let colors: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Text("Lap \(lapNumber)")
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(colors.onSurface)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(duration)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurface)
                
                Text(distance)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(pace)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.surface.opacity(0.5))
        )
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

 
