//
//  WorkoutPickerView.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import SwiftUI
import HealthKit

struct WorkoutPickerView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    private let workoutTypes: [(HKWorkoutActivityType, String, String)] = [
        (.running, "🏃‍♂️", "Running"),
        (.walking, "🚶‍♂️", "Walking"),
        (.cycling, "🚴‍♂️", "Cycling"),
        (.swimming, "🏊‍♂️", "Swimming"),
        (.yoga, "🧘‍♀️", "Yoga"),
        (.functionalStrengthTraining, "💪", "Strength"),
        (.highIntensityIntervalTraining, "🔥", "HIIT"),
        (.mixedCardio, "❤️", "Cardio"),
        (.stairClimbing, "🏢", "Stairs"),
        (.rowing, "🚣‍♂️", "Rowing")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workoutTypes, id: \.0) { workoutType in
                    Button(action: {
                        workoutManager.startWorkout(type: workoutType.0)
                        dismiss()
                    }) {
                        HStack {
                            Text(workoutType.1)
                                .font(.title2)
                            
                            Text(workoutType.2)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Choose Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WorkoutPickerView()
        .environmentObject(WorkoutManager())
} 