//
//  AIPredictionsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct AIPredictionsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var predictions: [HealthPrediction] = []
    @State private var isLoading = true
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if isLoading {
                        loadingSection
                    } else {
                        predictionsSection
                        confidenceSection
                        recommendationsSection
                    }
                }
                .padding(20)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .task {
            await loadPredictions()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Health Predictions")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Machine learning insights based on your data")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(theme.primary)
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing your health patterns...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var predictionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Predictions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            ForEach(Array(predictions.enumerated()), id: \.offset) { index, prediction in
                PredictionCard(prediction: prediction, theme: theme)
            }
        }
    }
    
    private var confidenceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Confidence Levels")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(predictions.enumerated()), id: \.offset) { index, prediction in
                    ConfidenceBar(
                        title: prediction.title,
                        confidence: prediction.confidence,
                        theme: theme
                    )
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Recommendations")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if let recommendationPrediction = predictions.first(where: { $0.title.contains("Recommendations") }) {
                RecommendationCard(prediction: recommendationPrediction, theme: theme)
            }
        }
    }
    
    private func loadPredictions() async {
        isLoading = true
        predictions = await analyticsService.generateAIPredictions()
        isLoading = false
    }
}

struct PredictionCard: View {
    let prediction: HealthPrediction
    let theme: FitGlideTheme.Colors
    
    private var probabilityColor: Color {
        let probability = prediction.probability
        if probability >= 0.8 { return .green }
        else if probability >= 0.6 { return .blue }
        else if probability >= 0.4 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.title)
                        .font(FitGlideTheme.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text(prediction.timeframe)
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prediction.predictedValue)
                        .font(FitGlideTheme.titleSmall)
                        .fontWeight(.bold)
                        .foregroundColor(probabilityColor)
                    
                    Text("\(Int(prediction.probability * 100))%")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            
            Text(prediction.reasoning)
                .font(FitGlideTheme.bodySmall)
                .foregroundColor(theme.onSurfaceVariant)
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ConfidenceBar: View {
    let title: String
    let confidence: Double
    let theme: FitGlideTheme.Colors
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .blue }
        else if confidence >= 0.4 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(Int(confidence * 100))%")
                    .font(FitGlideTheme.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.surfaceVariant)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * confidence, height: 8)
                        .animation(.easeInOut(duration: 1.0), value: confidence)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RecommendationCard: View {
    let prediction: HealthPrediction
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalized Recommendations")
                        .font(FitGlideTheme.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Based on your health patterns")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
            }
            
            Text(prediction.predictedValue)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurface)
                .lineLimit(nil)
            
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(theme.primary)
                
                Text("AI-powered insights")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
} 