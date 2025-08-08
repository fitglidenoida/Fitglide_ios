//
//  ActiveWorkoutView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: HomeViewModel
    
    let workoutType: WorkoutType
    @StateObject private var workoutManager = ActiveWorkoutManager()
    @StateObject private var audioService = AudioWorkoutService()
    @StateObject private var liveCheerService: LiveCheerService
    
    @State private var showStopConfirmation = false
    @State private var showWorkoutSummary = false
    @State private var animateContent = false
    @State private var lastAnnouncedDistance: Double = 0
    @State private var lastAnnouncedPace: Double = 0
    @State private var showLiveCheer = false
    
    init(workoutType: WorkoutType, viewModel: HomeViewModel) {
        self.workoutType = workoutType
        self.viewModel = viewModel
        let authRepo = AuthRepository()
        let strapiRepo = StrapiRepository(authRepository: authRepo)
        self._liveCheerService = StateObject(wrappedValue: LiveCheerService(strapiRepository: strapiRepo, authRepository: authRepo))
    }
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Header
                workoutHeader
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Timer Section
                        workoutTimerSection
                        
                        // Metrics Section
                        workoutMetricsSection
                        
                        // Progress Section
                        workoutProgressSection
                        
                        // Controls Section
                        workoutControlsSection
                        
                        // Live Cheer Section
                        if showLiveCheer {
                            LiveCheerView(
                                liveCheerService: liveCheerService,
                                colors: colors
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startWorkout()
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onReceive(workoutManager.$workoutData) { workoutData in
            checkMilestones(workoutData: workoutData)
        }
        .onDisappear {
            workoutManager.stopWorkout()
        }
        .alert("Stop Workout?", isPresented: $showStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop", role: .destructive) {
                stopWorkout()
            }
        } message: {
            Text("Are you sure you want to stop this workout?")
        }
        .fullScreenCover(isPresented: $showWorkoutSummary) {
            WorkoutSummaryView(
                viewModel: viewModel,
                workoutData: workoutManager.workoutData,
                workoutType: workoutType
            )
        }
    }
    
    // MARK: - Header
    private var workoutHeader: some View {
        HStack {
            Button(action: {
                if workoutManager.isWorkoutActive {
                    showStopConfirmation = true
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(colors.onSurface)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(workoutType.displayName)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Text(workoutManager.isWorkoutActive ? "Active" : "Paused")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(workoutManager.isWorkoutActive ? .green : .orange)
            }
            
            Spacer()
            
            Button(action: {
                workoutManager.togglePause()
            }) {
                Image(systemName: workoutManager.isWorkoutActive ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Timer Section
    private var workoutTimerSection: some View {
        VStack(spacing: 16) {
            Text(workoutManager.formattedDuration)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(colors.onSurface)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
            
            Text("Duration")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Metrics Section
    private var workoutMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            WorkoutMetricCard(
                title: "Distance",
                value: workoutManager.formattedDistance,
                icon: "figure.walk",
                color: .blue,
                colors: colors,
                animateContent: $animateContent,
                delay: 0.3
            )
            
            WorkoutMetricCard(
                title: "Pace",
                value: workoutManager.formattedPace,
                icon: "speedometer",
                color: .green,
                colors: colors,
                animateContent: $animateContent,
                delay: 0.4
            )
            
            WorkoutMetricCard(
                title: "Calories",
                value: "\(Int(workoutManager.workoutData.calories))",
                icon: "flame.fill",
                color: .orange,
                colors: colors,
                animateContent: $animateContent,
                delay: 0.5
            )
            
            WorkoutMetricCard(
                title: "Heart Rate",
                value: workoutManager.formattedHeartRate,
                icon: "heart.fill",
                color: .red,
                colors: colors,
                animateContent: $animateContent,
                delay: 0.6
            )
        }
    }
    
    // MARK: - Progress Section
    private var workoutProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Text("\(Int(workoutManager.workoutData.distance))m / 5km")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            ProgressView(value: min(workoutManager.workoutData.distance / 5000, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Controls Section
    private var workoutControlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button(action: {
                    workoutManager.addLap()
                    audioService.playLapSound()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                            .font(.title2)
                            .foregroundColor(colors.primary)
                        
                        Text("Lap")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                }
                
                Button(action: {
                    showLiveCheer.toggle()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text("Cheers")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                }
                
                Button(action: {
                    showStopConfirmation = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Stop")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                }
            }
            
            // Live Cheer View
            if showLiveCheer {
                LiveCheerView(
                    liveCheerService: liveCheerService,
                    colors: colors
                )
            }
        }
    }
    
    // MARK: - Actions
    private func startWorkout() {
        workoutManager.startWorkout(type: workoutType)
        audioService.announceWorkoutStart(type: workoutType)
        audioService.playStartSound()
        
        // Start live cheer when workout starts
        // Note: workoutId will be set after startWorkout is called
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let workoutId = self.workoutManager.workoutId {
                self.liveCheerService.startLiveCheer(workoutId: workoutId)
            }
        }
    }
    
    private func stopWorkout() {
        workoutManager.stopWorkout()
        audioService.announceWorkoutComplete(
            duration: workoutManager.workoutData.duration,
            distance: workoutManager.workoutData.distance,
            calories: workoutManager.workoutData.calories
        )
        audioService.playCompleteSound()
        
        // Stop live cheer when workout ends
        liveCheerService.stopLiveCheer()
        
        showWorkoutSummary = true
    }
    
    private func checkMilestones(workoutData: ActiveWorkoutData) {
        // Distance milestones (every 500m)
        let distanceMilestone = Int(workoutData.distance / 500) * 500
        if distanceMilestone > Int(lastAnnouncedDistance) && distanceMilestone > 0 {
            audioService.announceDistance(distance: Double(distanceMilestone))
            lastAnnouncedDistance = Double(distanceMilestone)
        }
        
        // Pace milestones (every 30 seconds change)
        let currentPace = workoutData.duration / (workoutData.distance / 1000)
        let paceDifference = abs(currentPace - lastAnnouncedPace)
        if paceDifference > 30 && workoutData.distance > 1000 {
            audioService.announcePace(pace: currentPace)
            lastAnnouncedPace = currentPace
        }
        
        // Heart rate alerts (if too high)
        if workoutData.heartRate > 180 {
            audioService.playHeartRateAlert()
        }
        
        // Live Cheer achievements
        liveCheerService.checkForAchievements(workoutData: workoutData)
    }
}

// MARK: - Workout Metric Card
struct WorkoutMetricCard: View {
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