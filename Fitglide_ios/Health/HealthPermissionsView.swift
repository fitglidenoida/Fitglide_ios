//
//  HealthPermissionsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//

import Foundation
import SwiftUI
import HealthKit
import os.log

struct HealthPermissionsView: View {
    @StateObject private var viewModel: HealthPermissionsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    init(viewModel: HealthPermissionsViewModel = HealthPermissionsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(colors.primary)
                        
                        Text("Health & Fitness Tracking")
                            .font(FitGlideTheme.titleLarge)
                            .foregroundColor(colors.onSurface)
                            .multilineTextAlignment(.center)
                        
                        Text("FitGlide needs access to your health data to provide personalized insights and track your fitness journey.")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    // Data Categories
                    VStack(spacing: 16) {
                        DataCategoryCard(
                            title: "Activity & Fitness",
                            description: "Steps, workouts, exercise minutes, and stand hours",
                            icon: "figure.walk",
                            colors: colors
                        )
                        
                        DataCategoryCard(
                            title: "Heart & Cardiovascular",
                            description: "Heart rate, blood pressure, HRV, and VO2 max",
                            icon: "heart.circle",
                            colors: colors
                        )
                        
                        DataCategoryCard(
                            title: "Sleep & Recovery",
                            description: "Sleep stages, respiratory rate, and recovery metrics",
                            icon: "bed.double",
                            colors: colors
                        )
                        
                        DataCategoryCard(
                            title: "Body Composition",
                            description: "Weight, BMI, body fat percentage, and height",
                            icon: "person.crop.circle",
                            colors: colors
                        )
                        
                        DataCategoryCard(
                            title: "Nutrition & Hydration",
                            description: "Calories, macronutrients, water intake, and vitamins",
                            icon: "drop.circle",
                            colors: colors
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Privacy Notice
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(colors.primary)
                            Text("Your Privacy Matters")
                                .font(FitGlideTheme.titleMedium)
                                .foregroundColor(colors.onSurface)
                            Spacer()
                        }
                        
                        Text("All health data is stored securely on your device and in your iCloud account. We only access data you explicitly grant permission for, and you can revoke access at any time.")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(colors.surfaceVariant.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await viewModel.requestHealthPermissions()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Grant Health Access")
                            }
                            .font(FitGlideTheme.bodyLarge)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isRequesting)
                        
                        Button(action: {
                            viewModel.openHealthSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Health Settings")
                            }
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(colors.primary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip for Now")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            viewModel.checkCurrentPermissions()
        }
    }
}

struct DataCategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let colors: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(colors.primary)
                .frame(width: 40, height: 40)
                .background(colors.primary.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FitGlideTheme.titleMedium)
                    .foregroundColor(colors.onSurface)
                
                Text(description)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(16)
        .background(colors.surface)
        .cornerRadius(12)
    }
}

class HealthPermissionsViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.fitglide", category: "HealthPermissionsViewModel")
    
    @Published var isRequesting = false
    @Published var hasPermissions = false
    
    func checkCurrentPermissions() {
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, _ in
            DispatchQueue.main.async {
                self.hasPermissions = status == .unnecessary
            }
        }
    }
    
    func requestHealthPermissions() async {
        await MainActor.run {
            isRequesting = true
        }
        
        do {
            let readTypes: Set<HKObjectType> = [
                // Basic Activity
                HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                
                // Heart & Cardiovascular
                HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
                
                // Sleep & Recovery
                HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
                
                // Body Composition
                HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
                HKQuantityType.quantityType(forIdentifier: .height)!,
                
                // Nutrition & Hydration
                HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
                
                // Fitness & Performance
                HKObjectType.workoutType(),
                HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
                HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
            ]
            
            let writeTypes: Set<HKSampleType> = [
                HKObjectType.workoutType(),
                HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
            ]
            
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            
            await MainActor.run {
                self.hasPermissions = true
                self.isRequesting = false
            }
            
            logger.info("HealthKit permissions granted successfully")
        } catch {
            await MainActor.run {
                self.isRequesting = false
            }
            logger.error("Failed to request HealthKit permissions: \(error.localizedDescription)")
        }
    }

    func openHealthSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            logger.error("Invalid settings URL")
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL) { success in
                self.logger.info("Opening Health settings: \(success)")
            }
        } else {
            logger.error("Cannot open settings URL")
        }
    }
}

struct HealthPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthPermissionsView()
            .previewDisplayName("Health Permissions View")
    }
}
