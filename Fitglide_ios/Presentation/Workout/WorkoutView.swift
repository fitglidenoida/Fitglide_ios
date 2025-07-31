//
//  WorkoutView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import SwiftUI
import HealthKit

struct WorkoutView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var navigationViewModel: NavigationViewModel
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showDetails = false
    @State private var showCreateWorkout = false
    @State private var showSettings = false
    @State private var selectedDate = Date()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var animateContent = false
    @State private var showMotivationalQuote = false
    @State private var showWorkoutDetail = false
    @State private var selectedWorkoutLog: WorkoutLogEntry? = nil
    
    private let userName: String
    
    init(userName: String, navigationViewModel: NavigationViewModel, viewModel: WorkoutViewModel) {
        self.userName = userName
        self.navigationViewModel = navigationViewModel
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    colors: [
                        theme.background,
                        theme.surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header
                    ModernWorkoutHeader(
                        userName: userName,
                        selectedDate: $selectedDate,
                        showSettings: $showSettings,
                        theme: theme,
                        animateContent: $animateContent
                    )
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Motivational Quote Card
                            if showMotivationalQuote {
                                MotivationalQuoteCard(theme: theme)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Enhanced Steps Section
                            ModernStepsSection(
                                steps: Int(viewModel.workoutData.steps),
                                goal: Int(viewModel.stepGoal),
                                theme: theme,
                                animateContent: $animateContent
                            )
                            
                            // Enhanced Metrics Row
                            ModernMetricsRow(
                                heartRate: Int(viewModel.workoutData.heartRate),
                                caloriesBurned: Int(viewModel.workoutData.caloriesBurned),
                                stressScore: Int(viewModel.stressScore),
                                maxHeartRate: Int(viewModel.maxHeartRate),
                                theme: theme,
                                animateContent: $animateContent
                            )
                            
                            // Enhanced Current Workout
                            ModernCurrentWorkout(
                                workout: currentWorkout,
                                viewModel: viewModel,
                                navigationViewModel: navigationViewModel,
                                theme: theme,
                                animateContent: $animateContent
                            )
                            
                            // Enhanced Workout Plans
                            ModernWorkoutPlans(
                                plans: plansForDate,
                                viewModel: viewModel,
                                navigationViewModel: navigationViewModel,
                                theme: theme,
                                animateContent: $animateContent
                            )
                            
                            // Completed Workouts Section
                            ModernCompletedWorkouts(
                                completedWorkouts: completedWorkoutsForDate,
                                onWorkoutTap: { workout in
                                    selectedWorkoutLog = workout
                                    showWorkoutDetail = true
                                },
                                theme: theme,
                                animateContent: $animateContent
                            )
                            
                            // Enhanced Quick Actions
                            ModernQuickActions(
                                viewModel: viewModel,
                                showCreateWorkout: $showCreateWorkout,
                                theme: theme,
                                animateContent: $animateContent
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for tab bar
                    }
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
            .sheet(isPresented: $showWorkoutDetail) {
                if let workoutLog = selectedWorkoutLog {
                    let authRepo = AuthRepository()
                    let strapiRepo = StrapiRepository(authRepository: authRepo)
                    let healthService = HealthService()
                    
                    WorkoutDetailView(
                        workoutId: workoutLog.documentId,
                        strapiRepository: strapiRepo,
                        authRepository: authRepo,
                        healthService: healthService
                    )
                }
            }
        }
    }
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private var currentWorkout: WorkoutSlot? {
        viewModel.workoutData.schedule.first { $0.date == selectedDate && $0.type == viewModel.workoutData.selectedGoal && $0.moves.contains { !$0.isCompleted } }
    }
    
    private var plansForDate: [WorkoutSlot] {
        viewModel.workoutData.plans.filter { $0.date == selectedDate }
    }
    
    private var completedWorkoutsForDate: [WorkoutLogEntry] {
        return viewModel.completedWorkouts
    }
}

// MARK: - Modern Workout Header
struct ModernWorkoutHeader: View {
    let userName: String
    @Binding var selectedDate: Date
    @Binding var showSettings: Bool
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
                    
                    Text("Ready to crush it, \(userName)?")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showSettings.toggle() }) {
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Date Selector
            ModernDateSelector(selectedDate: $selectedDate, theme: theme, animateContent: $animateContent)
        }
        .padding(.bottom, 16)
        .background(
            theme.background
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern Date Selector
struct ModernDateSelector: View {
    @Binding var selectedDate: Date
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
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
            .padding(.horizontal, 20)
        }
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Motivational Quote Card
struct MotivationalQuoteCard: View {
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

// MARK: - Modern Steps Section
struct ModernStepsSection: View {
    let steps: Int
    let goal: Int
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
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

// MARK: - Modern Metrics Row
struct ModernMetricsRow: View {
    let heartRate: Int
    let caloriesBurned: Int
    let stressScore: Int
    let maxHeartRate: Int
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ModernMetricCard(
                title: "Heart Rate",
                value: "\(heartRate)",
                unit: "bpm",
                icon: "heart.fill",
                color: .red,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.2
            )
            
            ModernMetricCard(
                title: "Calories",
                value: "\(caloriesBurned)",
                unit: "kcal",
                icon: "flame.fill",
                color: .orange,
                theme: theme,
                animateContent: $animateContent,
                delay: 0.3
            )
            
            ModernMetricCard(
                title: "Stress",
                value: "\(stressScore)",
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

// MARK: - Modern Metric Card
struct ModernMetricCard: View {
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

// MARK: - Modern Current Workout
struct ModernCurrentWorkout: View {
    let workout: WorkoutSlot?
    let viewModel: WorkoutViewModel
    let navigationViewModel: NavigationViewModel
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        if let workout = workout {
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
                    
                    Button(action: {
                        // Navigate to workout detail
                    }) {
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
                        Text(workout.type)
                            .font(FitGlideTheme.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        Text("\(workout.moves.filter { $0.isCompleted }.count)/\(workout.moves.count)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    
                    ProgressView(value: Double(workout.moves.filter { $0.isCompleted }.count) / Double(workout.moves.count))
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
}

// MARK: - Modern Workout Plans
struct ModernWorkoutPlans: View {
    let plans: [WorkoutSlot]
    let viewModel: WorkoutViewModel
    let navigationViewModel: NavigationViewModel
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        if !plans.isEmpty {
            VStack(spacing: 16) {
            HStack {
                    Text("Today's Plans")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("\(plans.count) workouts")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                LazyVStack(spacing: 12) {
                    ForEach(Array(plans.enumerated()), id: \.offset) { index, plan in
                        ModernWorkoutPlanCard(
                            plan: plan,
                            index: index,
                            theme: theme,
                            animateContent: $animateContent
                        )
                    }
                }
            }
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
        }
    }
}

// MARK: - Modern Workout Plan Card
struct ModernWorkoutPlanCard: View {
    let plan: WorkoutSlot
    let index: Int
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.type)
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("\(plan.moves.count) exercises")
                    .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
            }
                        
                        Spacer()
                        
            Button(action: {
                // Start workout
            }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.onPrimary)
                    .frame(width: 32, height: 32)
                    .background(theme.primary)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7 + Double(index) * 0.1), value: animateContent)
    }
}

// MARK: - Modern Quick Actions
struct ModernQuickActions: View {
    let viewModel: WorkoutViewModel
    @Binding var showCreateWorkout: Bool
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
                ModernQuickActionButton(
                    title: "Create Workout",
                    icon: "plus.circle.fill",
                    color: theme.primary,
                    action: { showCreateWorkout.toggle() },
                    theme: theme,
                    animateContent: $animateContent,
                    delay: 0.8
                )
                
                ModernQuickActionButton(
                    title: "Browse Plans",
                    icon: "list.bullet",
                    color: .blue,
                    action: { /* Browse plans */ },
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

// MARK: - Modern Quick Action Button
struct ModernQuickActionButton: View {
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

// MARK: - Modern Completed Workouts
struct ModernCompletedWorkouts: View {
    let completedWorkouts: [WorkoutLogEntry]
    let onWorkoutTap: (WorkoutLogEntry) -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Completed Workouts")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                if !completedWorkouts.isEmpty {
                    Text("\(completedWorkouts.count)")
                        .font(FitGlideTheme.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primary.opacity(0.1))
                        )
                }
            }
            
            if completedWorkouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("No completed workouts yet")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("Complete your first workout to see it here")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(completedWorkouts.enumerated()), id: \.offset) { index, workout in
                        ModernCompletedWorkoutCard(
                            workout: workout,
                            onTap: { onWorkoutTap(workout) },
                            theme: theme,
                            animateContent: $animateContent,
                            delay: 0.6 + Double(index) * 0.1
                        )
                    }
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
}

// MARK: - Modern Completed Workout Card
struct ModernCompletedWorkoutCard: View {
    let workout: WorkoutLogEntry
    let onTap: () -> Void
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    private var workoutIcon: String {
        switch workout.type?.lowercased() {
        case "running", "jogging":
            return "figure.run"
        case "cycling":
            return "bicycle"
        case "swimming":
            return "figure.pool.swim"
        case "walking":
            return "figure.walk"
        case "strength", "weightlifting":
            return "dumbbell.fill"
        case "yoga":
            return "figure.mind.and.body"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    private var workoutColor: Color {
        switch workout.type?.lowercased() {
        case "running", "jogging":
            return .orange
        case "cycling":
            return .blue
        case "swimming":
            return .cyan
        case "walking":
            return .green
        case "strength", "weightlifting":
            return .purple
        case "yoga":
            return .pink
        default:
            return theme.primary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(workoutColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: workoutIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(workoutColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title ?? workout.type ?? "Workout")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        if let duration = workout.totalTime, duration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(Int(duration / 60))m")
                                    .font(FitGlideTheme.caption)
                            }
                            .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        if let calories = workout.calories, calories > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(Int(calories)) cal")
                                    .font(FitGlideTheme.caption)
                            }
                            .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        if let distance = workout.distance, distance > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(String(format: "%.2f", distance)) km")
                                    .font(FitGlideTheme.caption)
                            }
                            .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatWorkoutDate(workout.startTime ?? Date()))
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: animateContent ? 0 : -20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: animateContent)
    }
    
    private func formatWorkoutDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}