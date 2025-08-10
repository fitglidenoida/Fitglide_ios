//
//  WorkoutShareView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import SwiftUI
import Charts

struct WorkoutShareView: View {
    let workout: WorkoutLogEntry
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var animateContent = false
    @State private var showMotivationalQuote = false
    @State private var selectedShareOption: ShareOption = .friends
    @State private var showChallengeCreation = false
    @State private var challengeTitle = ""
    @State private var challengeDescription = ""
    @State private var challengeDuration = 7
    @State private var selectedFriends: Set<String> = []
    @State private var selectedPacks: Set<String> = []
    @State private var showSuccessMessage = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    enum ShareOption: String, CaseIterable {
        case friends = "Friends"
        case packs = "Packs"
        case social = "Social Media"
        case challenge = "Create Challenge"
        
        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .packs: return "person.3.fill"
            case .social: return "square.and.arrow.up"
            case .challenge: return "trophy.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .friends: return .blue
            case .packs: return .green
            case .social: return .orange
            case .challenge: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
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
                
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Modern Header Section
                        modernHeaderSection
                        
                        // Motivational Quote (Indian focused)
                        if showMotivationalQuote {
                            indianMotivationalQuoteCard
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Workout Achievement Card
                        workoutAchievementCard
                        
                        // Share Options Section
                        shareOptionsSection
                        
                        // Challenge Creation Section (if selected)
                        if selectedShareOption == .challenge {
                            challengeCreationSection
                        }
                        
                        // Success Message
                        if showSuccessMessage {
                            successMessageCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show motivational quote after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMotivationalQuote = true
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareWorkout()
                    }
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.primary)
                    .disabled(selectedShareOption == .challenge && challengeTitle.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Your Achievement! 🎉")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Inspire others with your fitness journey")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Close Button
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.onSurface)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
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
    
    // MARK: - Indian Motivational Quote Card
    var indianMotivationalQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                
                Spacer()
                
                Text("Daily Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Text(workoutMotivationalQuotes.randomElement() ?? workoutMotivationalQuotes[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(colors.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Workout Achievement Card
    var workoutAchievementCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Complete! 💪")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                    
                    Text(workout.type ?? "Workout")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: workoutTypeIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                }
            }
            
            // Workout Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WorkoutStatCard(
                    title: "Duration",
                    value: formatDuration(TimeInterval(workout.totalTime ?? 0)),
                    icon: "clock.fill",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.2
                )
                
                WorkoutStatCard(
                    title: "Calories",
                    value: "\(Int(workout.calories ?? 0))",
                    icon: "flame.fill",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                WorkoutStatCard(
                    title: "Distance",
                    value: "\(String(format: "%.2f", workout.distance ?? 0)) km",
                    icon: "location.fill",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4
                )
                
                WorkoutStatCard(
                    title: "Heart Rate",
                    value: "\(workout.heartRateAverage ?? 0) bpm",
                    icon: "heart.fill",
                    color: .red,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.5
                )
            }
            
            // Achievement Badge
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Great Work!")
                        .font(FitGlideTheme.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)
                    
                    Text("You've completed another amazing workout")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
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
    
    // MARK: - Share Options Section
    var shareOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Share With")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(ShareOption.allCases, id: \.self) { option in
                    WorkoutShareOptionCard(
                        option: option,
                        isSelected: selectedShareOption == option,
                        action: { selectedShareOption = option },
                        theme: colors,
                        animateContent: $animateContent,
                        delay: 0.6 + Double(ShareOption.allCases.firstIndex(of: option) ?? 0) * 0.1
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Challenge Creation Section
    var challengeCreationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Create Challenge")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Challenge Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Title")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(colors.onSurface)
                    
                    TextField("e.g., 7-Day Fitness Challenge", text: $challengeTitle)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surfaceVariant.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                        )
                }
                
                // Challenge Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(colors.onSurface)
                    
                    TextField("Describe your challenge...", text: $challengeDescription, axis: .vertical)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surfaceVariant.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                        )
                        .lineLimit(3...6)
                }
                
                // Challenge Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration: \(challengeDuration) days")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(colors.onSurface)
                    
                    Slider(value: Binding(
                        get: { Double(challengeDuration) },
                        set: { challengeDuration = Int($0) }
                    ), in: 1...30, step: 1)
                    .accentColor(colors.primary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.surface)
                    .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateContent)
    }
    
    // MARK: - Success Message Card
    var successMessageCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Shared Successfully! 🎉")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Text("Your workout has been shared with your community")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var workoutTypeIcon: String {
        switch (workout.type ?? "").lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.mind.and.body"
        default: return "figure.mixed.cardio"
        }
    }
    
    private var workoutMotivationalQuotes: [String] {
        [
            "Every workout is a step towards your best self.",
            "Strength doesn't come from what you can do, it comes from overcoming what you thought you couldn't.",
            "Your body can stand almost anything. It's your mind you have to convince.",
            "The only bad workout is the one that didn't happen.",
            "Fitness is not about being better than someone else, it's about being better than you used to be."
        ]
    }
    
    // MARK: - Helper Functions
    private func formatDuration(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func shareWorkout() {
        switch selectedShareOption {
        case .social:
            shareToSocialMedia()
        case .friends:
            shareToFriends()
        case .packs:
            shareToPacks()
        case .challenge:
            createChallenge()
        }
    }
    
    private func shareToSocialMedia() {
        let shareText = """
🏃 FitGlide Workout Summary 🏃
Type: \(workout.type ?? "Workout")
Distance: \(String(format: "%.2f", workout.distance ?? 0)) km
Calories: \(Int(workout.calories ?? 0)) kcal
Duration: \(formatDuration(TimeInterval(workout.totalTime ?? 0)))
Avg HR: \(workout.heartRateAverage ?? 0) bpm
#FitGlide #Fitness #Workout
"""
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func shareToFriends() {
        // TODO: Implement friend sharing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showSuccessMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func shareToPacks() {
        // TODO: Implement pack sharing
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showSuccessMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    private func createChallenge() {
        // TODO: Implement challenge creation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showSuccessMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct WorkoutStatCard: View {
    let title: String
    let value: String
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
            
            VStack(spacing: 4) {
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}

struct WorkoutShareOptionCard: View {
    let option: WorkoutShareView.ShareOption
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? option.color.opacity(0.2) : option.color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? option.color : option.color.opacity(0.7))
                }
                
                Text(option.rawValue)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? theme.onSurface : theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? option.color.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? option.color.opacity(0.3) : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
}



// MARK: - Preview
#Preview {
    let mockWorkout = WorkoutLogEntry(
        id: 1,
        documentId: "doc1",
        logId: "log1",
        workout: nil,
        startTime: "2024-01-01T08:00:00Z",
        endTime: "2024-01-01T09:00:00Z",
        distance: 5.2,
        totalTime: 3600,
        calories: 450,
        heartRateAverage: 145,
        heartRateMaximum: 165,
        heartRateMinimum: 120,
        route: [],
        completed: true,
        notes: "Great morning run!",
        type: "Running"
    )
    
    WorkoutShareView(workout: mockWorkout)
}
