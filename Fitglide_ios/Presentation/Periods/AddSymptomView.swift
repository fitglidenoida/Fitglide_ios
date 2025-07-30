//
//  AddSymptomView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct AddSymptomView: View {
    @ObservedObject var viewModel: PeriodsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedSymptom = "Cramps"
    @State private var severity = SymptomSeverity.mild
    @State private var date = Date()
    @State private var customSymptom = ""
    @State private var showCustomSymptom = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private let commonSymptoms = [
        "Cramps", "Bloating", "Fatigue", "Mood Swings", 
        "Headache", "Back Pain", "Breast Tenderness", "Acne",
        "Food Cravings", "Insomnia", "Anxiety", "Depression"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 48))
                        .foregroundColor(theme.primary)
                    
                    Text("Add Symptom")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                    
                    Text("Track how you're feeling during your cycle")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // Form
                VStack(spacing: 24) {
                    // Symptom Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Symptom")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        if showCustomSymptom {
                            TextField("Enter custom symptom", text: $customSymptom)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(commonSymptoms, id: \.self) { symptom in
                                    SymptomButton(
                                        symptom: symptom,
                                        isSelected: selectedSymptom == symptom,
                                        action: { selectedSymptom = symptom },
                                        theme: theme
                                    )
                                }
                            }
                        }
                        
                        Button(action: { showCustomSymptom.toggle() }) {
                            HStack {
                                Image(systemName: showCustomSymptom ? "list.bullet" : "plus.circle")
                                Text(showCustomSymptom ? "Choose from list" : "Add custom symptom")
                            }
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.primary)
                        }
                    }
                    
                    // Severity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Severity")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(SymptomSeverity.allCases, id: \.self) { severityLevel in
                                SeverityButton(
                                    severity: severityLevel,
                                    isSelected: severity == severityLevel,
                                    action: { severity = severityLevel },
                                    theme: theme
                                )
                            }
                        }
                    }
                    
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                        
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveSymptom) {
                        Text("Save Symptom")
                            .font(FitGlideTheme.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(showCustomSymptom && customSymptom.isEmpty)
                    
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
    
    private func saveSymptom() {
        let symptomName = showCustomSymptom ? customSymptom : selectedSymptom
        viewModel.addSymptom(name: symptomName, severity: severity, date: date)
        dismiss()
    }
}

struct SymptomButton: View {
    let symptom: String
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            Text(symptom)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(isSelected ? theme.onPrimary : theme.onSurface)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? theme.primary : theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SeverityButton: View {
    let severity: SymptomSeverity
    let isSelected: Bool
    let action: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(severity.color)
                    .frame(width: 24, height: 24)
                
                Text(severity.rawValue)
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