//
//  WorkoutDetailView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/07/25.
//

import Foundation
import SwiftUI
import MapKit

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let workoutId: String
    let strapiRepository: StrapiRepository
    let authRepository: AuthRepository
    let healthService: HealthService
    
    @State private var workoutLog: WorkoutLogEntry? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var animateContent = false
    @State private var showWellnessQuote = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            if let log = workoutLog {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Modern Header Section
                            modernHeaderSection(log: log)
                            
                            // Indian Wellness Quote
                            if showWellnessQuote {
                                indianWellnessQuoteCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Workout Stats Overview
                            workoutStatsOverview(log: log)
                            
                            // Map Section (if available)
                    if let route = log.route, !route.isEmpty {
                                mapSection(route: route)
                            }
                            
                            // Detailed Metrics
                            detailedMetricsSection(log: log)
                            
                            // Heart Rate Zones (if available)
                            if log.heartRateAverage ?? 0 > 0 {
                                heartRateZonesSection(log: log)
                            }
                            
                            // Achievements Section
                            achievementsSection(log: log)
                            
                            // Quick Actions
                            quickActionsSection(log: log)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundColor(colors.primary)
                        
                        Text("Loading workout details...")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { shareWorkout(workoutLog!) }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
                
                // Show wellness quote after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showWellnessQuote = true
                    }
                }
                
                loadWorkoutDetails()
            }
        }
    }
    
    // MARK: - Modern Header Section
    func modernHeaderSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.type ?? "Workout")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text(formatDuration(log.totalTime ?? 0))
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Workout type icon
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    Image(systemName: workoutTypeIcon(log.type ?? ""))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Wellness Quote Card
    var indianWellnessQuoteCard: some View {
        VStack(spacing: 12) {
            Text("""
                "Every step you take is a step towards better health."
                """)
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(colors.onSurface)
            .multilineTextAlignment(.center)
            
            Text("Ancient Indian Wisdom")
                .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Workout Stats Overview
    func workoutStatsOverview(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workout Summary")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ModernWorkoutStatCard(
                    title: "Calories",
                    value: "\(Int(log.calories ?? 0))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.1
                )
                
                ModernWorkoutStatCard(
                    title: "Distance",
                    value: String(format: "%.1f", log.distance ?? 0),
                    unit: "km",
                    icon: "figure.walk",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.2
                )
                
                ModernWorkoutStatCard(
                    title: "Heart Rate",
                    value: "\(log.heartRateAverage ?? 0)",
                    unit: "bpm",
                    icon: "heart.fill",
                    color: .red,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                ModernWorkoutStatCard(
                    title: "Pace",
                    value: calculatePace(log),
                    unit: "/km",
                    icon: "speedometer",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Map Section
    func mapSection(route: [[String: Float]]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Route")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            // Placeholder for MapView - you'll need to implement this
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surfaceVariant)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundColor(colors.onSurfaceVariant)
                        Text("Route Map (\(route.count) points)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                )
                .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Detailed Metrics Section
    func detailedMetricsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
                                        HStack {
                Text("Detailed Metrics")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernDetailRow(
                    title: "Max Heart Rate",
                    value: "\(log.heartRateMaximum ?? 0) bpm",
                    icon: "heart.circle.fill",
                    color: .red,
                    theme: colors
                )
                
                ModernDetailRow(
                    title: "Min Heart Rate",
                    value: "\(log.heartRateMinimum ?? 0) bpm",
                    icon: "heart.circle",
                    color: .blue,
                    theme: colors
                )
                
                if let notes = log.notes, !notes.isEmpty {
                    ModernDetailRow(
                        title: "Notes",
                        value: notes,
                        icon: "note.text",
                        color: .purple,
                        theme: colors
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Heart Rate Zones Section
    func heartRateZonesSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Heart Rate Zones")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernZoneCard(
                    title: "Low Zone",
                    subtitle: "50-70%",
                    value: heartRateZone(log, low: 0.5, high: 0.7),
                    color: .green,
                    theme: colors
                )
                
                ModernZoneCard(
                    title: "Moderate Zone",
                    subtitle: "70-85%",
                    value: heartRateZone(log, low: 0.7, high: 0.85),
                    color: .orange,
                    theme: colors
                )
                
                ModernZoneCard(
                    title: "High Zone",
                    subtitle: "85-100%",
                    value: heartRateZone(log, low: 0.85, high: 1.0),
                    color: .red,
                    theme: colors
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Achievements Section
    func achievementsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            let achievements = getAchievements(log)
            if achievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 40))
                        .foregroundColor(colors.onSurfaceVariant.opacity(0.5))
                    
                    Text("No achievements yet")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("Keep pushing yourself to unlock achievements!")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievements, id: \.self) { badge in
                            ModernAchievementCard(
                                title: badge,
                                icon: "rosette.fill",
                                color: .yellow,
                                theme: colors
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Quick Actions Section
    func quickActionsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ModernButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    style: .primary
                ) {
                    shareWorkout(log)
                }
                
                ModernButton(
                    title: "Save",
                    icon: "bookmark",
                    style: .secondary
                ) {
                    // Save workout
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Helper Methods
    private func loadWorkoutDetails() {
        // Load workout details from API
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    alertMessage = "Missing user ID"
                    showAlert = true
                    return
                }

                // Try parsing logId as UUID date prefix (you can adjust this based on your logId format)
                let dateFromLogId = extractDateFromLogId(workoutId) ?? Date()
                let dateString = ISO8601DateFormatter().string(from: dateFromLogId).prefix(10) // yyyy-MM-dd

                let logs = try await strapiRepository.getWorkoutLogs(userId: userId, date: String(dateString))
                guard let strapiLog = logs.data.first(where: { $0.logId == workoutId }) else {
                    alertMessage = "Workout not found."
                    showAlert = true
                    return
                }

                let startTime = ISO8601DateFormatter().date(from: strapiLog.startTime) ?? Date()
                let workoutData = try await healthService.getWorkout(date: startTime)
                let heartRate = try await healthService.getHeartRate(date: startTime)

                workoutLog = WorkoutLogEntry(
                    id: strapiLog.id,
                    documentId: strapiLog.documentId,
                    logId: strapiLog.logId,
                    workout: strapiLog.workout,
                    startTime: strapiLog.startTime,
                    endTime: strapiLog.endTime,
                    distance: workoutData.distance ?? strapiLog.distance,
                    totalTime: workoutData.duration ?? strapiLog.totalTime,
                    calories: workoutData.calories ?? strapiLog.calories,
                    heartRateAverage: (heartRate.average > 0 ? heartRate.average : strapiLog.heartRateAverage),
                    heartRateMaximum: strapiLog.heartRateMaximum,
                    heartRateMinimum: strapiLog.heartRateMinimum,
                    route: strapiLog.route,
                    completed: strapiLog.completed,
                    notes: strapiLog.notes,
                    type: workoutData.type ?? strapiLog.type
                )
            } catch {
                alertMessage = "Error fetching workout: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func extractDateFromLogId(_ logId: String) -> Date? {
        let pattern = #"wearable_(\d{4}-\d{2}-\d{2})"#  // extract date portion
        if let match = logId.range(of: pattern, options: .regularExpression) {
            let dateString = String(logId[match]).replacingOccurrences(of: "wearable_", with: "")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: dateString)
        }
        return nil
    }


    private func shareWorkout(_ log: WorkoutLogEntry) {
        let shareText = """
🏃 FitGlide Workout Summary 🏃
Type: \(log.type ?? "Workout")
Distance: \(log.distance ?? 0) km
Calories: \(Int(log.calories ?? 0)) kcal
Duration: \(formatDuration(log.totalTime ?? 0))
Avg HR: \(log.heartRateAverage ?? 0) bpm
#FitGlide #Fitness
"""
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func workoutTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        default: return "figure.run"
        }
    }
}

// MARK: - Supporting Views

struct ModernWorkoutStatCard: View {
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
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ModernDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }
}

struct ModernZoneCard: View {
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(value)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }
}

struct ModernAchievementCard: View {
    let title: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    // Simple preview with mock data - no complex dependencies
    VStack(spacing: 20) {
        Text("WorkoutDetailView Preview")
            .font(.title)
            .fontWeight(.bold)
        
        Text("Beautiful modern workout detail view")
            .font(.body)
            .foregroundColor(.secondary)
        
        Text("🇮🇳 Indian wellness design")
            .font(.caption)
            .foregroundColor(.blue)
        
        // Mock workout stats
        HStack(spacing: 20) {
            VStack {
                Text("🏃‍♀️")
                    .font(.title)
                Text("Running")
                    .font(.caption)
            }
            
            VStack {
                Text("🔥")
                    .font(.title)
                Text("500 kcal")
                    .font(.caption)
            }
            
            VStack {
                Text("❤️")
                    .font(.title)
                Text("140 bpm")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    .padding()
}

// MARK: - Helper Functions
func formatDuration(_ time: Float) -> String {
    let hours = Int(time)
    let minutes = Int((time - Float(hours)) * 60)
    let seconds = Int(((time - Float(hours)) * 60 - Float(minutes)) * 60)
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func calculatePace(_ log: WorkoutLogEntry) -> String {
    let distance = log.distance ?? 0
    let totalTime = log.totalTime ?? 0
    if distance <= 0 || totalTime <= 0 { return "N/A" }
    let pace = totalTime / distance
    let minutes = Int(pace)
    let seconds = Int((pace - Float(minutes)) * 60)
    return String(format: "%d:%02d min/km", minutes, seconds)
}

func heartRateZone(_ log: WorkoutLogEntry, low: Float, high: Float) -> String {
    let maxHr = Float(log.heartRateMaximum ?? 0)
    if maxHr <= 0 { return "N/A" }
    let lowBpm = Int(maxHr * low)
    let highBpm = Int(maxHr * high)
    return "\(lowBpm) - \(highBpm) bpm"
}

func getAchievements(_ log: WorkoutLogEntry) -> [String] {
    var ach: [String] = []
    if (log.distance ?? 0) >= 5 { ach.append("5K Runner 🏃") }
    if (log.distance ?? 0) >= 10 { ach.append("10K Champion 🏅") }
    if (log.calories ?? 0) >= 500 { ach.append("Calorie Crusher 🔥") }
    return ach
}

func shareWorkout(_ log: WorkoutLogEntry) {
    // Implementation for sharing workout
    print("Sharing workout: \(log.type ?? "Unknown")")
}
