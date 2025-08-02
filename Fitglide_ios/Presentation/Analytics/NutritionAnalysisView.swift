//
//  NutritionAnalysisView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 30/07/25.
//

import SwiftUI

struct NutritionAnalysisView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    @State private var nutritionData = NutritionData(
        caloriesConsumed: 0,
        caloriesTarget: 2000,
        protein: 0,
        carbs: 0,
        fat: 0,
        proteinTarget: 120,
        carbsTarget: 250,
        fatTarget: 80,
        caloriesPercentage: 0.0,
        proteinPercentage: 0.0,
        carbsPercentage: 0.0,
        fatPercentage: 0.0
    )
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                mainContent
            }
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
            await loadNutritionData()
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            headerSection
            
            if isLoading {
                loadingSection
            } else {
                macroBreakdownSection
                calorieTrackingSection
                insightsSection
            }
        }
        .padding(20)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition Analysis")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Understand your eating patterns")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading nutrition data...")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var macroBreakdownSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MacroCard(
                title: "Protein",
                value: "\(nutritionData.protein)g",
                target: "\(nutritionData.proteinTarget)g",
                percentage: nutritionData.proteinPercentage,
                color: .blue,
                theme: theme
            )
            
            MacroCard(
                title: "Carbs",
                value: "\(nutritionData.carbs)g",
                target: "\(nutritionData.carbsTarget)g",
                percentage: nutritionData.carbsPercentage,
                color: .green,
                theme: theme
            )
            
            MacroCard(
                title: "Fat",
                value: "\(nutritionData.fat)g",
                target: "\(nutritionData.fatTarget)g",
                percentage: nutritionData.fatPercentage,
                color: .orange,
                theme: theme
            )
        }
    }
    
    private var calorieTrackingSection: some View {
        VStack(spacing: 20) {
            CalorieTrackingCard(
                consumed: nutritionData.caloriesConsumed,
                target: nutritionData.caloriesTarget,
                theme: theme
            )
            
            // Meal Distribution
            MealDistributionCard(
                theme: theme,
                breakfast: nutritionData.breakfastPercentage,
                lunch: nutritionData.lunchPercentage,
                dinner: nutritionData.dinnerPercentage,
                snacks: nutritionData.snacksPercentage
            )
        }
    }
    
    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Nutrition Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            if analyticsService.nutritionInsights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Text("No nutrition insights available")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                        .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            } else {
                ForEach(Array(analyticsService.nutritionInsights.prefix(3).enumerated()), id: \.offset) { index, insight in
                    InsightCard(
                        title: insight.title,
                        description: insight.description,
                        icon: insight.type.icon,
                        color: insight.type.color,
                        theme: theme
                    )
                }
            }
        }
    }
    
    private func loadNutritionData() async {
        isLoading = true
        
        // Load today's nutrition data from Strapi
        do {
            nutritionData = try await analyticsService.getTodayNutritionData()
            
            // Generate nutrition-specific insights
            await analyticsService.generateNutritionInsights()
            
            // Check if we should show a nudge to update diet plan
            let shouldNudge = try await analyticsService.checkDietPlanForNudge()
            if shouldNudge {
                // Add a nudge insight if needed
                await analyticsService.generateNutritionInsights()
            }
            
        } catch {
            print("NutritionAnalysisView: Failed to load nutrition data: \(error)")
            // Keep default empty nutrition data
        }
        
        isLoading = false
    }
    
    private func calculateNutritionData() async {
        // This method is no longer needed as we get real data from Strapi
        // Keeping it for backward compatibility but it's not used
    }
}

// MARK: - Supporting Models

struct MacroCard: View {
    let title: String
    let value: String
    let target: String
    let percentage: Double
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(value)
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
            
            Text("of \(target)")
                .font(FitGlideTheme.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: percentage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct CalorieTrackingCard: View {
    let consumed: Int
    let target: Int
    let theme: FitGlideTheme.Colors
    
    private var percentage: Double {
        Double(consumed) / Double(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Calories")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("Target: \(target) kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("\(consumed)")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("kcal")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                    
                    Spacer()
                    
                    Text("\(Int(percentage * 100))%")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(percentage >= 1.0 ? .green : .orange)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.surfaceVariant)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(percentage >= 1.0 ? Color.green : Color.orange)
                            .frame(width: geometry.size.width * min(percentage, 1.0), height: 8)
                            .animation(.easeInOut(duration: 1.0), value: percentage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct MealDistributionCard: View {
    let theme: FitGlideTheme.Colors
    let breakfast: Double
    let lunch: Double
    let dinner: Double
    let snacks: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meal Distribution")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Text("Today's calorie distribution")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            VStack(spacing: 12) {
                MealRow(
                    meal: "Breakfast",
                    calories: 420,
                    percentage: breakfast,
                    color: .blue,
                    theme: theme
                )
                
                MealRow(
                    meal: "Lunch",
                    calories: 580,
                    percentage: lunch,
                    color: .green,
                    theme: theme
                )
                
                MealRow(
                    meal: "Dinner",
                    calories: 650,
                    percentage: dinner,
                    color: .orange,
                    theme: theme
                )
                
                MealRow(
                    meal: "Snacks",
                    calories: 200,
                    percentage: snacks,
                    color: .purple,
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct MealRow: View {
    let meal: String
    let calories: Int
    let percentage: Double
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(meal)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
            
            Spacer()
            
            Text("\(calories) kcal")
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text("\(Int(percentage * 100))%")
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.onSurface)
        }
    }
} 