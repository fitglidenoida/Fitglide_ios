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
    private let userName: String
    
    init(userName: String, navigationViewModel: NavigationViewModel, viewModel: WorkoutViewModel) {
        self.userName = userName
        self.navigationViewModel = navigationViewModel
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView(userName: userName, selectedDate: $selectedDate, showSettings: $showSettings)
                    .frame(height: 80)
                
                ScrollView {
                    MainContentView(
                        viewModel: viewModel,
                        navigationViewModel: navigationViewModel,
                        selectedDate: $selectedDate,
                        showDetails: $showDetails,
                        showCreateWorkout: $showCreateWorkout,
                        showToast: $showToast,
                        toastMessage: $toastMessage,
                        userName: userName
                    )
                }
            }
            .background(theme.background.ignoresSafeArea())
        }
    }
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
}

struct MainContentView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    @Binding var selectedDate: Date
    @Binding var showDetails: Bool
    @Binding var showCreateWorkout: Bool
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    let userName: String
    @Environment(\.colorScheme) var colorScheme
    @State private var animateContent = false
    @State private var isLoading = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private var currentWorkout: WorkoutSlot? {
        viewModel.workoutData.schedule.first { $0.date == selectedDate && $0.type == viewModel.workoutData.selectedGoal && $0.moves.contains { !$0.isCompleted } }
    }
    
    private var plansForDate: [WorkoutSlot] {
        viewModel.workoutData.plans.filter { $0.date == selectedDate }
    }
    
    private var workoutsForDate: [WorkoutSlot] {
        viewModel.workoutData.schedule.filter { $0.date == selectedDate && $0.type == viewModel.workoutData.selectedGoal }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LazyVStack(spacing: 24) {
                StepsSectionView(steps: viewModel.workoutData.steps, goal: viewModel.stepGoal, theme: theme)

                MetricsRowView(
                    heartRate: viewModel.workoutData.heartRate,
                    caloriesBurned: viewModel.workoutData.caloriesBurned,
                    stressScore: viewModel.stressScore,
                    maxHeartRate: viewModel.maxHeartRate,
                    theme: theme
                )

                CurrentWorkoutView(workout: currentWorkout, viewModel: viewModel, navigationViewModel: navigationViewModel, theme: theme)

                WorkoutPlansView(plans: plansForDate, viewModel: viewModel, showToast: $showToast, toastMessage: $toastMessage, theme: theme)

                WorkoutLogsView(workouts: workoutsForDate, viewModel: viewModel, navigationViewModel: navigationViewModel, theme: theme)

                InsightsView(insights: viewModel.workoutData.insights, theme: theme)

                StreakView(streak: viewModel.workoutData.streak, theme: theme)
            }
            .id(selectedDate)
            .padding()
            .scaleEffect(animateContent ? 1 : 0.95)
            .opacity(animateContent ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateContent = true
                }
            }

            if showDetails {
                WorkoutDetailsView(workoutData: viewModel.workoutData, stressScore: viewModel.stressScore, theme: theme)
                    .transition(.opacity.combined(with: .scale))
            }
            
            FloatingActionButtonView(showCreateWorkout: $showCreateWorkout, theme: theme)
            
            if showToast {
                ToastView(message: toastMessage, showToast: $showToast, toastMessage: $toastMessage, theme: theme)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showCreateWorkout) {
            WorkoutPlanView(viewModel: viewModel, selectedDate: $selectedDate)
        }
        .task(id: selectedDate) {
            withAnimation(.easeOut(duration: 0.2)) {
                animateContent = false
            }
            await viewModel.fetchWorkoutData(for: selectedDate)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

struct HeaderView: View {
    let userName: String
    @Binding var selectedDate: Date
    @Binding var showSettings: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Hey \(userName), Power Up!")
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(theme.onSurface)
            
            HStack(spacing: 12) {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                }) {
                    Image(systemName: "chevron.left")
                        .font(FitGlideTheme.bodyLarge.bold())
                        .foregroundColor(theme.primary)
                        .padding(8)
                        .background(theme.surfaceVariant.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Text(formattedDate(selectedDate))
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(theme.onSurface)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                }) {
                    Image(systemName: "chevron.right")
                        .font(FitGlideTheme.bodyLarge.bold())
                        .foregroundColor(theme.primary)
                        .padding(8)
                        .background(theme.surfaceVariant.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .shadow(color: theme.onSurface.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
}

struct WorkoutSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Settings")
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(theme.onSurface)
            
            Text("Customize your workout preferences")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .font(FitGlideTheme.bodyLarge.bold())
            .foregroundColor(theme.onPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
            .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(24)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.2), radius: FitGlideTheme.Card.elevation, x: 0, y: 4)
        .frame(width: 300)
    }
}

struct StepsSectionView: View {
    let steps: Float
    let goal: Float
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(theme.onSurfaceVariant.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(steps / goal, 1)))
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: steps / goal)
                
                VStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(theme.tertiary)
                    
                    Text("\(Int(steps))")
                        .font(FitGlideTheme.titleLarge)
                        .foregroundColor(theme.onSurface)
                }
            }
            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text("Goal: \(Int(goal)) steps")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
    }
}

struct MetricsRowView: View {
    let heartRate: Float
    let caloriesBurned: Float
    let stressScore: Int
    let maxHeartRate: Float
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            MetricCircleView(value: heartRate, max: maxHeartRate, label: "BPM", color: theme.secondary, theme: theme)
            MetricCircleView(value: caloriesBurned, max: 500, label: "Cal", color: theme.tertiary, theme: theme)
            StressCircleView(stressScore: stressScore, color: theme.primary, theme: theme)
        }
        .padding()
    }
}

struct MetricCircleView: View {
    let value: Float
    let max: Float
    let label: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.onSurfaceVariant.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(value / max, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: value / max)
            
            VStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(FitGlideTheme.bodyLarge.bold())
                    .foregroundColor(theme.onSurface)
                Text(label)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
    }
}

struct StressCircleView: View {
    let stressScore: Int
    let color: Color
    let theme: FitGlideTheme.Colors
    
    private var progress: CGFloat {
        switch stressScore {
        case 0...33: return 0.3
        case 34...66: return 0.6
        default: return 0.9
        }
    }
    
    private var stressLabel: String {
        stressScore < 34 ? "Low" : stressScore < 67 ? "Medium" : "High"
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.onSurfaceVariant.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
            
            VStack(spacing: 2) {
                Text(stressLabel)
                    .font(FitGlideTheme.bodyLarge.bold())
                    .foregroundColor(theme.onSurface)
                Text("Stress")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
        }
    }
}

struct CurrentWorkoutView: View {
    let workout: WorkoutSlot?
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Current Workout", theme: theme)
            
            if let workout = workout {
                WorkoutCard(slot: workout, viewModel: viewModel, navigationViewModel: navigationViewModel, theme: theme)
            } else {
                Text("No active workout scheduled")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
}

struct WorkoutPlansView: View {
    let plans: [WorkoutSlot]
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Workout Plans", theme: theme)
            
            if plans.isEmpty {
                Text("No workout plans for this date")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            } else {
                ForEach(plans) { plan in
                    WorkoutPlanCard(slot: plan, viewModel: viewModel, showToast: $showToast, toastMessage: $toastMessage, theme: theme)
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
}

struct WorkoutLogsView: View {
    let workouts: [WorkoutSlot]
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Workout Log", theme: theme)
            
            if workouts.isEmpty {
                Text("No workouts logged for this date")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            } else {
                ForEach(workouts) { workout in
                    WorkoutCard(slot: workout, viewModel: viewModel, navigationViewModel: navigationViewModel, theme: theme)
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
}

struct InsightsView: View {
    let insights: [String]
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Insights", theme: theme)
            
            if insights.isEmpty {
                Text("Keep moving to get personalized insights!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            } else {
                ForEach(insights, id: \.self) { insight in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(theme.tertiary)
                            .font(.system(size: 20))
                        Text(insight)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                    }
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
}

struct StreakView: View {
    let streak: Int
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        if streak > 0 {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.onPrimary)
                
                Text("Streak: \(streak) days")
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(theme.onPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.primary.opacity(0.3), radius: FitGlideTheme.Card.elevation, x: 0, y: 4)
        }
    }
}

struct FloatingActionButtonView: View {
    @Binding var showCreateWorkout: Bool
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button("Create Workout") {
                        showCreateWorkout = true
                    }
                    Button("Share Success Story") {
                        // Placeholder for future implementation
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(theme.onPrimary)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary]), startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Circle())
                        .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(24)
            }
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onPrimary)
                .padding()
                .background(message.contains("Error") ? theme.tertiary : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                .padding()
                .shadow(color: theme.onSurface.opacity(0.2), radius: 4, x: 0, y: 2)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                        toastMessage = ""
                    }
                }
        }
    }
}

struct WorkoutPlanCard: View {
    let slot: WorkoutSlot
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var showToast: Bool
    @Binding var toastMessage: String
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Plan Details
            HStack(spacing: 12) {
                Image(systemName: iconForType(slot.type))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.primary)
                    .frame(width: 40, height: 40)
                    .background(theme.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(slot.type)
                        .font(FitGlideTheme.titleMedium)
                        .foregroundColor(theme.onSurface)
                    Text(slot.time)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            // Start Button
            if !slot.isCompleted {
                Button(action: {
                    viewModel.startWorkout(slot.id, friendIds: ["2", "3"]) { success, message in
                        showToast = true
                        toastMessage = message
                        if success {
                            Task {
                                await viewModel.saveWorkoutLog(slot: slot)
                            }
                        }
                    }
                }) {
                    Text("Start Workout")
                        .font(FitGlideTheme.titleMedium.bold())
                        .foregroundColor(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
                        .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            } else {
                Text("All workouts done!")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(theme.quaternary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .background(theme.quaternary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Exercises List
            if slot.moves.isEmpty {
                Text("No exercises planned")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(slot.moves.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(slot.moves[index].name)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        Text(slot.moves[index].repsOrTime)
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        if !slot.isCompleted {
                            Image(systemName: slot.moves[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(slot.moves[index].isCompleted ? theme.quaternary : theme.onSurfaceVariant)
                                .font(.system(size: 24))
                                .onTapGesture {
                                    viewModel.toggleMove(slotId: slot.id, moveIndex: index)
                                }
                        }
                    }
                    if index < slot.moves.count - 1 {
                        Divider()
                            .background(theme.onSurfaceVariant.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio": return "figure.run"
        case "flex": return "figure.yoga"
        default: return "dumbbell.fill"
        }
    }
}

struct WorkoutCard: View {
    let slot: WorkoutSlot
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var navigationViewModel: NavigationViewModel
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Workout Details
            HStack(spacing: 12) {
                Image(systemName: iconForType(slot.type))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(theme.primary)
                    .frame(width: 40, height: 40)
                    .background(theme.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(slot.type)
                        .font(FitGlideTheme.titleMedium)
                        .foregroundColor(theme.onSurface)
                    Text(slot.time)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
            }
            
            // Metrics
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(theme.secondary)
                    Text("\(Int(viewModel.workoutData.heartRate)) bpm")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(theme.tertiary)
                    Text("\(Int(viewModel.workoutData.caloriesBurned)) cal")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            .padding(.vertical, 8)
            .background(theme.surfaceVariant.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Moves
            if slot.moves.isEmpty {
                Text("No exercises recorded")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(slot.moves.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(slot.moves[index].name)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        Text(slot.moves[index].repsOrTime)
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    if index < slot.moves.count - 1 {
                        Divider()
                            .background(theme.onSurfaceVariant.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio": return "figure.run"
        case "flex": return "figure.yoga"
        default: return "dumbbell.fill"
        }
    }
}

struct WorkoutDetailsView: View {
    let workoutData: WorkoutUiData
    let stressScore: Int
    let theme: FitGlideTheme.Colors
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Details")
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(theme.onSurface)
            
            infoRow(icon: "flame.fill", label: "Calories Burned: \(Int(workoutData.caloriesBurned)) cal", color: theme.tertiary)
            infoRow(icon: "heart.fill", label: "Heart Rate: \(Int(workoutData.heartRate)) BPM", color: theme.secondary)
            infoRow(icon: "figure.walk", label: "Steps: \(Int(workoutData.steps))", color: theme.primary)
            infoRow(icon: "bolt.fill", label: "Stress: \(stressScore < 34 ? "Low" : stressScore < 67 ? "Medium" : "High")", color: theme.quaternary)
            
            Button("Close") {
                dismiss()
            }
            .font(FitGlideTheme.bodyLarge.bold())
            .foregroundColor(theme.onPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
            .shadow(color: theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(24)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
        .shadow(color: theme.onSurface.opacity(0.2), radius: FitGlideTheme.Card.elevation, x: 0, y: 4)
        .frame(width: 320)
    }
    
    private func infoRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            Text(label)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SurfaceView<Content: View>: View {
    let content: () -> Content
    let theme: FitGlideTheme.Colors
    
    init(theme: FitGlideTheme.Colors, @ViewBuilder content: @escaping () -> Content) {
        self.theme = theme
        self.content = content
    }
    
    var body: some View {
        content()
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                    .stroke(theme.onSurfaceVariant.opacity(0.2), lineWidth: 1)
            )
    }
}

// Preview
struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let authRepository = AuthRepository(appleAuthManager: AppleAuthManager())
        let strapiRepository = StrapiRepository(api: StrapiApiClient(), authRepository: authRepository)
        let healthService = HealthService()
        let workoutViewModel = WorkoutViewModel(strapiRepository: strapiRepository, healthService: healthService, authRepository: authRepository)
        
        WorkoutView(
            userName: "Test User",
            navigationViewModel: NavigationViewModel(),
            viewModel: workoutViewModel
        )
        .environment(\.colorScheme, .light)
    }
}
