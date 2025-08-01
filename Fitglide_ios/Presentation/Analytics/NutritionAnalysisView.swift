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
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
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
                        
                        // Macro Breakdown
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            MacroCard(
                                title: "Protein",
                                value: "85g",
                                target: "120g",
                                percentage: 0.71,
                                color: .blue,
                                theme: theme
                            )
                            
                            MacroCard(
                                title: "Carbs",
                                value: "220g",
                                target: "250g",
                                percentage: 0.88,
                                color: .green,
                                theme: theme
                            )
                            
                            MacroCard(
                                title: "Fat",
                                value: "65g",
                                target: "80g",
                                percentage: 0.81,
                                color: .orange,
                                theme: theme
                            )
                        }
                    }
                    
                    // Calorie Tracking
                    VStack(spacing: 20) {
                        CalorieTrackingCard(
                            consumed: 1850,
                            target: 2100,
                            theme: theme
                        )
                        
                        // Meal Distribution
                        MealDistributionCard(theme: theme)
                    }
                    
                    // Insights
                    VStack(spacing: 16) {
                        HStack {
                            Text("Nutrition Insights")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            InsightRow(
                                title: "Protein Intake",
                                description: "You're 29% below your protein goal. Consider adding more lean protein sources.",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Good Hydration",
                                description: "You're meeting your daily water intake goals consistently.",
                                icon: "drop.fill",
                                color: .blue,
                                theme: theme
                            )
                            
                            InsightRow(
                                title: "Balanced Meals",
                                description: "Your meal timing is well-distributed throughout the day.",
                                icon: "clock.fill",
                                color: .green,
                                theme: theme
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

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
                    percentage: 0.23,
                    color: .blue,
                    theme: theme
                )
                
                MealRow(
                    meal: "Lunch",
                    calories: 580,
                    percentage: 0.31,
                    color: .green,
                    theme: theme
                )
                
                MealRow(
                    meal: "Dinner",
                    calories: 650,
                    percentage: 0.35,
                    color: .orange,
                    theme: theme
                )
                
                MealRow(
                    meal: "Snacks",
                    calories: 200,
                    percentage: 0.11,
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