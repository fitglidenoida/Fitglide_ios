//
//  StartWorkoutView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var selectedWorkoutType: WorkoutType = .walking
    @State private var showActiveWorkout = false
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
                
                VStack(spacing: 0) {
                    // Header with proper spacing
                    VStack(spacing: 16) {
                        Text("Start Workout")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(colors.onSurface)
                        
                        Text("Choose your activity type")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Workout Type Selection with proper grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                                WorkoutTypeCard(
                                    workoutType: workoutType,
                                    isSelected: selectedWorkoutType == workoutType,
                                    onTap: { selectedWorkoutType = workoutType },
                                    colors: colors,
                                    animateContent: $animateContent
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Fixed bottom button
                    VStack {
                        Button(action: {
                            startWorkout()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                
                                Text("Start \(selectedWorkoutType.displayName)")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colors.primary)
                                    .shadow(color: colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .background(colors.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                ActiveWorkoutView(
                    workoutType: selectedWorkoutType,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private func startWorkout() {
        showActiveWorkout = true
    }
}

// MARK: - Workout Type Card
struct WorkoutTypeCard: View {
    let workoutType: WorkoutType
    let isSelected: Bool
    let onTap: () -> Void
    let colors: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? colors.primary.opacity(0.15) : colors.surface)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? colors.primary : colors.surfaceVariant, lineWidth: isSelected ? 2 : 1)
                        )
                    
                    Image(systemName: workoutType.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isSelected ? colors.primary : colors.onSurface)
                }
                
                Text(workoutType.displayName)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? colors.primary : colors.onSurface)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? colors.primary.opacity(0.05) : colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? colors.primary : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? colors.primary.opacity(0.2) : colors.onSurface.opacity(0.08), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateContent)
    }
} 