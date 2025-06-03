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
            Form {
                WorkoutDetailsSection(
                    workoutType: $workoutType,
                    title: $title,
                    duration: $duration,
                    distance: $distance,
                    description: $description,
                    isTemplate: $isTemplate,
                    selectedDate: $selectedDate,
                    isCardio: isCardio
                )
                
                RepeatSection(
                    repeatType: $repeatType,
                    repeatCount: $repeatCount,
                    selectedDays: $selectedDays
                )
                
                if !isCardio {
                    ExercisesSection(
                        exercises: $exercises,
                        showingExerciseSelector: $showingExerciseSelector,
                        selectedExerciseIndex: $selectedExerciseIndex,
                        filteredExercises: filteredExercises,
                        searchQuery: $searchQuery
                    )
                }
            }
            .navigationTitle("Create Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkouts()
                    }
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(FitGlideTheme.colors(for: colorScheme).primary)
                    .disabled(!isValid)
                }
            }
            .task {
                await viewModel.fetchExercises()
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !duration.isEmpty && (isCardio ? !distance.isEmpty : !exercises.isEmpty)
    }
    
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

struct WorkoutDetailsSection: View {
    @Binding var workoutType: String
    @Binding var title: String
    @Binding var duration: String
    @Binding var distance: String
    @Binding var description: String
    @Binding var isTemplate: Bool
    @Binding var selectedDate: Date
    let isCardio: Bool
    
    var body: some View {
        Section(header: Text("Workout Details").font(.custom("Poppins-Bold", size: 16))) {
            TextField("Title", text: $title)
                .font(.custom("Poppins-Regular", size: 14))
            Picker("Type", selection: $workoutType) {
                ForEach(sportTypes, id: \.self) { type in
                    Text(type).tag(type)
                        .font(.custom("Poppins-Regular", size: 14))
                }
            }
            TextField("Duration (minutes)", text: $duration)
                .keyboardType(.numberPad)
                .font(.custom("Poppins-Regular", size: 14))
            if isCardio {
                TextField("Distance (km)", text: $distance)
                    .keyboardType(.decimalPad)
                    .font(.custom("Poppins-Regular", size: 14))
            }
            DatePicker("Start Date", selection: $selectedDate, displayedComponents: .date)
                .font(.custom("Poppins-Regular", size: 14))
            TextField("Description (optional)", text: $description)
                .font(.custom("Poppins-Regular", size: 14))
            Toggle("Save as Template", isOn: $isTemplate)
                .font(.custom("Poppins-Regular", size: 14))
        }
    }
}

struct RepeatSection: View {
    @Binding var repeatType: RepeatType
    @Binding var repeatCount: Int
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        Section(header: Text("Repeat").font(.custom("Poppins-Bold", size: 16))) {
            Picker("Repeat Type", selection: $repeatType) {
                ForEach(RepeatType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            if repeatType != .none {
                Stepper("Repeat for \(repeatCount) \(repeatType == .daily ? "days" : "weeks")", value: $repeatCount, in: 1...52)
            }
            if repeatType == .weekly {
                MultiSelectPicker("Days of Week", selection: $selectedDays, options: Weekday.allCases)
            }
        }
    }
}

struct ExercisesSection: View {
    @Binding var exercises: [ExerciseInput]
    @Binding var showingExerciseSelector: Bool
    @Binding var selectedExerciseIndex: Int?
    let filteredExercises: [ExerciseEntry]
    @Binding var searchQuery: String

    @State private var triggerSheet: Bool = false  // avoids double-present bug

    var body: some View {
        VStack {
            Section(header: Text("Exercises").font(.custom("Poppins-Bold", size: 16))) {
                ForEach(exercises.indices, id: \.self) { index in
                    ExerciseInputView(exercise: $exercises[index]) {
                        if !showingExerciseSelector && !triggerSheet {
                            selectedExerciseIndex = index
                            triggerSheet = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showingExerciseSelector = true
                                triggerSheet = false
                            }
                        }
                    }
                }
                .onDelete { indices in
                    exercises.remove(atOffsets: indices)
                }

                Button("Add Exercise") {
                    exercises.append(ExerciseInput())
                }
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)
                .padding()
                .background(FitGlideTheme.colors(for: .light).primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorSheet(
                filteredExercises: filteredExercises,
                searchQuery: $searchQuery,
                selectedExerciseIndex: $selectedExerciseIndex,
                exercises: $exercises,
                showingSheet: $showingExerciseSelector
            )
        }
    }
}

struct ExerciseSelectorSheet: View {
    let filteredExercises: [ExerciseEntry]
    @Binding var searchQuery: String
    @Binding var selectedExerciseIndex: Int?
    @Binding var exercises: [ExerciseInput]
    @Binding var showingSheet: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises, id: \.id) { ex in
                    Text(ex.name ?? "Unknown")
                        .onTapGesture {
                            if let index = selectedExerciseIndex {
                                exercises[index].exerciseId = String(ex.id)
                                exercises[index].exerciseName = ex.name ?? ""
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showingSheet = false
                                selectedExerciseIndex = nil
                            }
                        }
                }
            }
            .searchable(text: $searchQuery)
            .navigationTitle("Select Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSheet = false
                        selectedExerciseIndex = nil
                    }
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

