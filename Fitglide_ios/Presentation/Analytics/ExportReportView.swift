//
//  ExportReportView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct ExportReportView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedReportType = 0
    @State private var selectedTimeRange = 0
    @State private var isGenerating = false
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private let reportTypes = ["Health Summary", "Fitness Report", "Nutrition Analysis", "Sleep Report"]
    private let timeRanges = ["Last 7 days", "Last 30 days", "Last 3 months", "Last 6 months"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export Report")
                                    .font(FitGlideTheme.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Generate and export your health data")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Report Type Selection
                    VStack(spacing: 16) {
                        HStack {
                            Text("Report Type")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(Array(reportTypes.enumerated()), id: \.offset) { index, type in
                                ReportTypeCard(
                                    title: type,
                                    isSelected: selectedReportType == index,
                                    onTap: { selectedReportType = index },
                                    theme: theme
                                )
                            }
                        }
                    }
                    
                    // Time Range Selection
                    VStack(spacing: 16) {
                        HStack {
                            Text("Time Range")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(Array(timeRanges.enumerated()), id: \.offset) { index, range in
                                TimeRangeCard(
                                    title: range,
                                    isSelected: selectedTimeRange == index,
                                    onTap: { selectedTimeRange = index },
                                    theme: theme
                                )
                            }
                        }
                    }
                    
                    // Export Button
                    Button(action: {
                        generateReport()
                    }) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                            }
                            
                            Text(isGenerating ? "Generating..." : "Generate Report")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private func generateReport() {
        isGenerating = true
        
        // Simulate report generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
            // Here you would implement actual report generation
            // For now, just show a success message
            dismiss()
        }
    }
}

struct ReportTypeCard: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Comprehensive \(title.lowercased()) with charts and insights")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeRangeCard: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 