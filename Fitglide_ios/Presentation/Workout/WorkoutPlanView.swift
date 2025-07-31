//
//  WorkoutPlanView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/07/25.
//

import Foundation
import SwiftUI

struct WorkoutPlanView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var workoutType = "Cardio"
    @State private var title = ""
    @State private var duration = ""
    @State private var distance = ""
    @State private var description = ""
    @State private var isTemplate = false
    @State private var exercises: [ExerciseInput] = []
    @State private var showingExerciseSelector = false
    @State private var selectedExerciseIndex: Int?
    @State private var searchQuery = ""
    @State private var repeatType: RepeatType = .none
    @State private var repeatCount = 1
    @State private var selectedDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var animateContent = false
    @State private var showIndianWisdom = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private var isCardio: Bool {
        ["Running", "Cycling", "Swimming", "Hiking", "Jogging", "Rowing", "Cardio", "Dance Fitness"].contains(workoutType)
    }
    
    private var filteredExercises: [ExerciseEntry] {
        if searchQuery.isEmpty {
            return viewModel.availableExercises
        } else {
            return viewModel.availableExercises.filter { $0.name?.lowercased().contains(searchQuery.lowercased()) ?? false }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with Indian wellness gradient
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header Section (Stationary)
                    modernHeaderSection
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Indian Wellness Quote
                            if showIndianWisdom {
                                indianWellnessQuoteCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Workout Details Card
                            workoutDetailsCard
                            
                            // Repeat Settings Card
                            repeatSettingsCard
                            
                            // Exercises Card (if not cardio)
                            if !isCardio {
                                exercisesCard
                            }
                            
                            // Quick Actions
                            quickActionsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show Indian wisdom after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showIndianWisdom = true
                    }
                }
                
                // Fetch exercises
                Task {
                    await viewModel.fetchExercises()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(FitGlideTheme.bodyMedium)
                    }
                    .foregroundColor(colors.primary)
                }
                
                Spacer()
                
                Text("Create Workout")
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button(action: { saveWorkouts() }) {
                    Text("Save")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.background)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isValid ? colors.primary : colors.onSurfaceVariant)
                        )
                }
                .disabled(!isValid)
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
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Spacer()
                
                Text("Indian Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Text(indianWorkoutWisdom.randomElement() ?? indianWorkoutWisdom[0])
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
    
    // MARK: - Workout Details Card
    var workoutDetailsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workout Details")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Title
                ModernTextField(
                    title: "Workout Title",
                    text: $title,
                    placeholder: "Enter workout title",
                    icon: "dumbbell.fill"
                )
                
                // Type Picker
                ModernPicker(
                    title: "Workout Type",
                    selection: $workoutType,
                    options: sportTypes,
                    icon: "figure.run"
                )
                
                // Duration
                ModernTextField(
                    title: "Duration (minutes)",
                    text: $duration,
                    placeholder: "30",
                    icon: "clock.fill",
                    keyboardType: .numberPad
                )
                
                // Distance (for cardio)
                if isCardio {
                    ModernTextField(
                        title: "Distance (km)",
                        text: $distance,
                        placeholder: "5.0",
                        icon: "location.fill",
                        keyboardType: .decimalPad
                    )
                }
                
                // Description
                ModernTextField(
                    title: "Description (optional)",
                    text: $description,
                    placeholder: "Add workout description",
                    icon: "text.quote"
                )
                
                // Template Toggle
                HStack {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colors.primary)
                    
                    Text("Save as Template")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurface)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isTemplate)
                        .toggleStyle(SwitchToggleStyle(tint: colors.primary))
                }
                .padding(.vertical, 8)
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
    
    // MARK: - Repeat Settings Card
    var repeatSettingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Repeat Settings")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Repeat Type
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "repeat")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colors.primary)
                        
                        Text("Repeat Type")
                            .font(FitGlideTheme.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    
                    Menu {
                        ForEach(RepeatType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                repeatType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(repeatType.rawValue)
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surfaceVariant)
                        )
                    }
                }
                
                // Repeat Count
                if repeatType != .none {
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.primary)
                        
                        Text("Repeat for \(repeatCount) \(repeatType == .daily ? "days" : "weeks")")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        Spacer()
                        
                        Stepper("", value: $repeatCount, in: 1...52)
                            .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }
                
                // Days of Week (for weekly)
                if repeatType == .weekly {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(colors.primary)
                            
                            Text("Days of Week")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                Button(action: {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }) {
                                    Text(day.shortName)
                                        .font(FitGlideTheme.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedDays.contains(day) ? colors.background : colors.onSurface)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(selectedDays.contains(day) ? colors.primary : colors.surfaceVariant)
                                        )
                                }
                            }
                        }
                    }
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Exercises Card
    var exercisesCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercises")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button(action: { showingExerciseSelector = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Exercise")
                            .font(FitGlideTheme.bodyMedium)
                    }
                    .foregroundColor(colors.primary)
                }
            }
            
            if exercises.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("No exercises added")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("Tap 'Add Exercise' to get started")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                        ModernExerciseCard(
                            exercise: exercise,
                            onDelete: { exercises.remove(at: index) },
                            onEdit: { selectedExerciseIndex = index }
                        )
                    }
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
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorView(
                exercises: filteredExercises,
                searchQuery: $searchQuery,
                onSelect: { exercise in
                    exercises.append(ExerciseInput(
                        exerciseId: exercise.documentId,
                        exerciseName: exercise.name ?? "",
                        sets: 3,
                        reps: 12,
                        weight: 0,
                        restBetweenSets: 60
                    ))
                }
            )
        }
    }
    
    // MARK: - Quick Actions Section
    var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ModernQuickActionButton(
                    title: "Save Template",
                    icon: "bookmark.fill",
                    color: colors.primary,
                    action: { isTemplate = true; saveWorkouts() },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4
                )
                
                ModernQuickActionButton(
                    title: "Start Now",
                    icon: "play.fill",
                    color: colors.quaternary,
                    action: { saveWorkouts() },
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.5
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var isValid: Bool {
        !title.isEmpty && !duration.isEmpty && (isCardio ? !distance.isEmpty : !exercises.isEmpty)
    }
    
    private var indianWorkoutWisdom: [String] {
        [
            "Strength does not come from the physical capacity. It comes from an indomitable will.",
            "The body achieves what the mind believes.",
            "Your body can stand almost anything. It's your mind you have to convince.",
            "The only bad workout is the one that didn't happen.",
            "Discipline is choosing between what you want now and what you want most."
        ]
    }
    
    // MARK: - Helper Functions
    private func saveWorkouts() {
        let dates = computeDates()
        for date in dates {
            viewModel.createWorkout(
                title: title,
                type: workoutType,
                duration: Float(duration) ?? 0,
                distance: Float(distance) ?? 0,
                description: description,
                exerciseInputs: exercises,
                isTemplate: isTemplate,
                date: date
            )
        }
        dismiss()
    }
    
    private func computeDates() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        let startWeekday = calendar.component(.weekday, from: selectedDate)
        
        switch repeatType {
        case .none:
            dates.append(selectedDate)
        case .daily:
            for i in 0..<repeatCount {
                if let date = calendar.date(byAdding: .day, value: i, to: selectedDate) {
                    dates.append(date)
                }
            }
        case .weekly:
            for week in 0..<repeatCount {
                for day in selectedDays {
                    let dayOffset = day.rawValue - startWeekday + (week * 7)
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: selectedDate) {
                        dates.append(date)
                    }
                }
            }
        }
        return dates.sorted()
    }
}

// MARK: - Modern Text Field
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            TextField(placeholder, text: $text)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurface)
                .keyboardType(keyboardType)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surfaceVariant)
                )
        }
    }
}

// MARK: - Modern Picker
struct ModernPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let icon: String
    
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colors.primary)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Select \(title.lowercased())" : selection)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(selection.isEmpty ? colors.onSurfaceVariant : colors.onSurface)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colors.onSurfaceVariant)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surfaceVariant)
                )
            }
        }
    }
}

// MARK: - Modern Exercise Card
struct ModernExerciseCard: View {
    let exercise: ExerciseInput
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Text("\(exercise.sets) sets × \(exercise.reps) reps")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colors.primary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colors.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surfaceVariant)
        )
    }
}



// MARK: - Exercise Selector View
struct ExerciseSelectorView: View {
    let exercises: [ExerciseEntry]
    @Binding var searchQuery: String
    let onSelect: (ExerciseEntry) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.onSurfaceVariant)
            
            TextField("Search exercises...", text: $searchQuery)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(colors.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surfaceVariant)
        )
        .padding(.horizontal, 20)
    }
    
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(exercises, id: \.documentId) { exercise in
                    exerciseCard(for: exercise)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func exerciseCard(for exercise: ExerciseEntry) -> some View {
        Button(action: {
            onSelect(exercise)
            dismiss()
        }) {
            HStack(spacing: 12) {
                exerciseIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)
                    
                    Text(exercise.type ?? "General")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseIcon: some View {
        ZStack {
            Circle()
                .fill(colors.primary.opacity(0.15))
                .frame(width: 40, height: 40)
            
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colors.primary)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                searchBarSection
                exerciseListSection
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(colors.primary)
                }
            }
        }
    }
}


enum RepeatType: String, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    
    var id: Self { self }
}

enum Weekday: Int, CaseIterable, Identifiable, Comparable, CustomStringConvertible {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct MultiSelectPicker<Option: Hashable & Comparable & CaseIterable>: View where Option.AllCases: RandomAccessCollection, Option: CustomStringConvertible {
    let title: String
    @Binding var selection: Set<Option>
    let options: [Option]
    
    init(_ title: String, selection: Binding<Set<Option>>, options: [Option] = Array(Option.allCases)) {
        self.title = title
        self._selection = selection
        self.options = options.sorted()
    }
    
    var body: some View {
        List {
            ForEach(options, id: \.self) { option in
                HStack {
                    Text(option.description)
                    Spacer()
                    if selection.contains(option) {
                        Image(systemName: "checkmark")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selection.contains(option) {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}

struct ExerciseInput: Identifiable {
    let id = UUID()
    var exerciseId: String = ""
    var exerciseName: String = ""
    var sets: Int = 0
    var reps: Int = 0
    var weight: Int = 0
    var restBetweenSets: Int = 0
}

struct ExerciseInputView: View {
    @Binding var exercise: ExerciseInput
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Exercise")
                    .fontWeight(.bold)
                Spacer()
                Text(exercise.exerciseName.isEmpty ? "Select Exercise" : exercise.exerciseName)
                    .foregroundColor(exercise.exerciseName.isEmpty ? .gray : .primary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            TextField("Sets", value: $exercise.sets, format: .number)
                .keyboardType(.numberPad)
            TextField("Reps", value: $exercise.reps, format: .number)
                .keyboardType(.numberPad)
            TextField("Weight (kg)", value: $exercise.weight, format: .number)
                .keyboardType(.numberPad)
            TextField("Rest (seconds)", value: $exercise.restBetweenSets, format: .number)
                .keyboardType(.numberPad)
        }
    }
}

private let sportTypes = [
    "Running", "Cycling", "Swimming", "Hiking", "Strength", "Cardio",
    "Full-Body", "Lower Body", "Upper Body", "Core", "Hybrid (Strength + Cardio)",
    "Plyometric (Explosive)", "Functional Training", "Flexibility and Mobility",
    "Powerlifting", "Bodyweight Training", "High-Intensity Interval Training (HIIT)",
    "Pilates", "Yoga", "Circuit Training", "Isometric Training", "Endurance Training",
    "Agility and Speed Training", "Rehabilitation and Low-Impact", "Dance Fitness",
    "Rowing", "Badminton", "Tennis", "Jogging"
]

