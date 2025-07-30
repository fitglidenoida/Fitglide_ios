//
//  AddPeriodView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct AddPeriodView: View {
    @ObservedObject var viewModel: PeriodsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var startDate = Date()
    @State private var duration = 5
    @State private var flow = FlowIntensity.medium
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(theme.primary)
                    
                    Text("Add Period")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                    
                    Text("Track your menstrual cycle to get personalized insights")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // Form
                VStack(spacing: 24) {
                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration: \(duration) days")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        Slider(value: Binding(
                            get: { Double(duration) },
                            set: { duration = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(theme.primary)
                        
                        HStack {
                            Text("1 day")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                            
                            Spacer()
                            
                            Text("10 days")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                    
                    // Flow Intensity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flow Intensity")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(FlowIntensity.allCases, id: \.self) { intensity in
                                FlowIntensityButton(
                                    intensity: intensity,
                                    isSelected: flow == intensity,
                                    action: { flow = intensity },
                                    theme: theme
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: savePeriod) {
                        Text("Save Period")
                            .font(FitGlideTheme.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(FitGlideTheme.bodyLarge)
                            .foregroundColor(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    private func savePeriod() {
        viewModel.addPeriod(startDate: startDate, duration: duration, flow: flow)
        dismiss()
    }
}

struct FlowIntensityButton: View {
    let intensity: FlowIntensity
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(intensity.color)
                    .frame(width: 32, height: 32)
                
                Text(intensity.rawValue)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurface)
            }
            .padding()
            .background(isSelected ? theme.primary.opacity(0.1) : theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 