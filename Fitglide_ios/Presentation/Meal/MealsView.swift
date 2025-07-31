//
//  MealsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 17/06/25.
//

import SwiftUI
import PhotosUI
import os.log

struct MealsView: View {
    @ObservedObject var viewModel: MealsViewModel
    @State private var showDetails = false
    @State private var showWeeklyInsights = false
    @State private var showMealPicker = false
    @State private var showPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoConfirmation = false
    @State private var isProcessingPhoto = false
    @State private var photoMealData: PhotoMealData?
    @State private var selectedDate: Date
    @State private var isLoading = false
    @State private var searchQuery: String = ""
    @State private var selectedFavorites: Set<String> = []
    @State private var animateContent = false
    @State private var showIndianNutritionTip = false
    
    let mealTypes = ["Veg", "Non-Veg", "Mixed"]
    @Environment(\.colorScheme) var colorScheme
    
    private let theme = FitGlideTheme.self
    private let logger = Logger(subsystem: "com.fitglide.meals", category: "MealsView")
    
    init(viewModel: MealsViewModel) {
        self.viewModel     = viewModel
        _selectedDate      = State(initialValue: Date())   // start at today
    }

    var body: some View {
        NavigationView {
        ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [
                        theme.colors(for: colorScheme).background,
                        theme.colors(for: colorScheme).surface.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            if isLoading {
                ProgressView("Loading meal data...")
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Modern Header Section
                            modernHeaderSection
                            
                            // Indian Nutrition Tip
                            if showIndianNutritionTip {
                                indianNutritionTipCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Daily Nutrition Overview
                            dailyNutritionOverview
                            
                                                    // Indian Meal Categories
                        indianMealCategoriesSection
                            
                            // Today's Meals
                            todaysMealsSection
                            
                            // Indian Recipe Suggestions
                            indianRecipeSuggestions
                            
                            // Quick Actions
                            modernQuickActionsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
                
                // Show Indian nutrition tip after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showIndianNutritionTip = true
                    }
                }
                
                guard !viewModel.didInitialize else { return }
                Task {
                    await viewModel.setDate(selectedDate)
                    await viewModel.initializeData()
                    await viewModel.fetchRecipes()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem)
        .onChange(of: photoPickerItem) { _, newItem in
            Task {
                if let item = newItem, let data = try? await item.loadTransferable(type: Data.self),
                   let _ = UIImage(data: data) {
                    isProcessingPhoto = true
                    let foodName = "Pizza" // TODO: Replace with food recognition API
                    let calories: Float = 800
                    let protein: Float = 30
                    let carbs: Float = 100
                    let fat: Float = 35
                    let fiber: Float = 5
                    photoMealData = PhotoMealData(
                        mealName: foodName,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        fiber: fiber
                    )
                    showPhotoConfirmation = true
                    isProcessingPhoto = false
                } else {
                    logger.error("Failed to capture photo")
                }
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            Task { await viewModel.setDate(newValue) }
        }
        .sheet(isPresented: $showMealPicker) {
            MealPickerDialog(
                viewModel:  viewModel,
                mealTypes:  mealTypes,
                onDismiss: { showMealPicker = false }
            )
        }
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition & Meals 🍽️")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors(for: colorScheme).onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text("Track your daily nutrition journey")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.colors(for: colorScheme).onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Add Meal Button
                Button(action: { showMealPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(theme.colors(for: colorScheme).primary)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.colors(for: colorScheme).primary.opacity(0.3), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                    }
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Date Selector
            modernDateSelector
        }
        .padding(.bottom, 16)
        .background(
            theme.colors(for: colorScheme).background
                .shadow(color: theme.colors(for: colorScheme).onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Modern Date Selector
    var modernDateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(-3...3, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
                    
                    Button(action: { selectedDate = date }) {
        VStack(spacing: 4) {
                            Text(dayOfWeek(for: date))
                                .font(FitGlideTheme.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? theme.colors(for: colorScheme).onPrimary : theme.colors(for: colorScheme).onSurfaceVariant)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? theme.colors(for: colorScheme).onPrimary : theme.colors(for: colorScheme).onSurface)
                        }
                        .frame(width: 50, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? theme.colors(for: colorScheme).primary : (isToday ? theme.colors(for: colorScheme).primary.opacity(0.1) : theme.colors(for: colorScheme).surface))
                        )
        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday && !isSelected ? theme.colors(for: colorScheme).primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(offset + 3) * 0.05), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Indian Nutrition Tip Card
    var indianNutritionTipCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
                
                Spacer()
                
                Text("Indian Nutrition Tip")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors(for: colorScheme).onSurfaceVariant)
            }
            
            Text(indianNutritionTips.randomElement() ?? indianNutritionTips[0])
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(theme.colors(for: colorScheme).onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors(for: colorScheme).surface)
                .shadow(color: theme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Daily Nutrition Overview
    var dailyNutritionOverview: some View {
        VStack(spacing: 16) {
        HStack {
                Text("Today's Nutrition")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                
            Spacer()
                
                Text("\(Int(viewModel.mealsDataState.caloriesLogged)) / \(Int(viewModel.mealsDataState.targetKcal)) kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors(for: colorScheme).surfaceVariant)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                    LinearGradient(
                        colors: [theme.colors(for: colorScheme).primary, theme.colors(for: colorScheme).secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                    .frame(width: UIScreen.main.bounds.width * 0.8 * calorieProgress, height: 8)
                    .scaleEffect(x: animateContent ? 1.0 : 0.0, anchor: .leading)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
            }
            
            // Nutrition Metrics Grid
            HStack(spacing: 12) {
                ModernNutritionMetricCard(
                    title: "Protein",
                    value: "\(Int(viewModel.mealsDataState.protein))g",
                    unit: "of \(Int(viewModel.mealsDataState.proteinGoal))g",
                    icon: "leaf.fill",
                    color: .green,
                    theme: theme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.2
                )
                
                ModernNutritionMetricCard(
                    title: "Carbs",
                    value: "\(Int(viewModel.mealsDataState.carbs))g",
                    unit: "of \(Int(viewModel.mealsDataState.carbsGoal))g",
                    icon: "flame.fill",
                    color: .orange,
                    theme: theme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                ModernNutritionMetricCard(
                    title: "Fat",
                    value: "\(Int(viewModel.mealsDataState.fat))g",
                    unit: "of \(Int(viewModel.mealsDataState.fatGoal))g",
                    icon: "drop.fill",
                    color: .blue,
                    theme: theme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.4
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.colors(for: colorScheme).surface)
                .shadow(color: theme.colors(for: colorScheme).onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Indian Meal Categories
    var indianMealCategoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Indian Meal Categories")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indianMealCategoryItems, id: \.self) { category in
                        IndianMealCategoryCard(
                            title: category.title,
                            icon: category.icon,
                            color: category.color,
                            theme: theme.colors(for: colorScheme),
                            animateContent: $animateContent,
                            delay: 0.5 + Double(indianMealCategoryItems.firstIndex(of: category) ?? 0) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Today's Meals Section
    var todaysMealsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Meals")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                Button("Add Meal") {
                    showMealPicker = true
                }
                .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.mealsDataState.schedule.enumerated()), id: \.offset) { index, mealSlot in
                    ModernMealCard(
                        mealSlot: mealSlot,
                        index: index,
                        theme: theme.colors(for: colorScheme),
                        animateContent: $animateContent
                    )
                }
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Indian Recipe Suggestions
    var indianRecipeSuggestions: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Indian Recipe Suggestions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                
                Spacer()
                
                Button("View All") {
                    // Show all recipes
                }
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(indianRecipes, id: \.self) { recipe in
                        IndianRecipeCard(
                            title: recipe.title,
                            calories: recipe.calories,
                            time: recipe.time,
                            image: recipe.image,
                            theme: theme.colors(for: colorScheme),
                            animateContent: $animateContent,
                            delay: 0.7 + Double(indianRecipes.firstIndex(of: recipe) ?? 0) * 0.1
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: animateContent)
    }
    
    // MARK: - Modern Quick Actions Section
    var modernQuickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(FitGlideTheme.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors(for: colorScheme).onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ModernMealQuickActionButton(
                    title: "Log Meal",
                    icon: "plus.circle.fill",
                    color: theme.colors(for: colorScheme).primary,
                    action: { showMealPicker = true },
                    theme: theme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 0.9
                )
                
                ModernMealQuickActionButton(
                    title: "Photo Log",
                    icon: "camera.fill",
                    color: .blue,
                    action: { showPhotoPicker = true },
                    theme: theme.colors(for: colorScheme),
                    animateContent: $animateContent,
                    delay: 1.0
                )
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: animateContent)
    }
    
    // MARK: - Helper Properties
    private var calorieProgress: Double {
        min(Double(viewModel.mealsDataState.caloriesLogged) / Double(viewModel.mealsDataState.targetKcal), 1.0)
    }
    
    private var indianNutritionTips: [String] {
        [
            "Include a variety of colorful vegetables in your daily meals.",
            "Opt for whole grains like brown rice and whole wheat rotis.",
            "Include protein-rich foods like dal, paneer, and legumes.",
            "Stay hydrated with water, coconut water, and herbal teas.",
            "Practice mindful eating and savor each bite."
        ]
    }
    
    private var indianMealCategoryItems: [IndianMealCategory] {
        [
            IndianMealCategory(title: "Breakfast", icon: "sunrise.fill", color: .orange),
            IndianMealCategory(title: "Lunch", icon: "sun.max.fill", color: .yellow),
            IndianMealCategory(title: "Snacks", icon: "cup.and.saucer.fill", color: .brown),
            IndianMealCategory(title: "Dinner", icon: "moon.fill", color: .purple),
            IndianMealCategory(title: "Desserts", icon: "birthday.cake.fill", color: .pink)
        ]
    }
    
    private var indianRecipes: [IndianRecipe] {
        [
            IndianRecipe(title: "Masala Dosa", calories: 280, time: "25 min", image: "dosa"),
            IndianRecipe(title: "Palak Paneer", calories: 320, time: "20 min", image: "palak"),
            IndianRecipe(title: "Chicken Curry", calories: 450, time: "35 min", image: "curry"),
            IndianRecipe(title: "Dal Khichdi", calories: 380, time: "30 min", image: "khichdi")
        ]
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    struct ModernNutritionMetricCard: View {
        let title: String
        let value: String
        let unit: String
        let icon: String
        let color: Color
        let theme: FitGlideTheme.Colors
        @Binding var animateContent: Bool
        let delay: Double
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
            HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Text(title)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                Text(value)
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
        }
    }
    
    struct IndianMealCategoryCard: View {
        let title: String
        let icon: String
        let color: Color
        let theme: FitGlideTheme.Colors
        @Binding var animateContent: Bool
        let delay: Double
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
        }
    }
    
    struct ModernMealCard: View {
        let mealSlot: MealSlot
        let index: Int
        let theme: FitGlideTheme.Colors
        @Binding var animateContent: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
            HStack {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundColor(theme.primary)
                    Text(mealSlot.type)
                    .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                Text("Calories: \(Int(mealSlot.calories)) Kcal")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text("Protein: \(Int(mealSlot.protein))g, Carbs: \(Int(mealSlot.carbs))g, Fat: \(Int(mealSlot.fat))g")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                HStack {
                    Button(action: { /* Action for consuming meal */ }) {
                        Text("Consume")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: { /* Action for replace meal */ }) {
                        Text("Replace")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.onSurfaceVariant, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8 + Double(index) * 0.05), value: animateContent)
        }
    }
    
    struct IndianRecipeCard: View {
        let title: String
        let calories: Float
        let time: String
        let image: String
        let theme: FitGlideTheme.Colors
        @Binding var animateContent: Bool
        let delay: Double
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 100)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    .lineLimit(1)
                    Text("Calories: \(Int(calories)) Kcal")
                    .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    Text("Time: \(time)")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
        }
    }
    
    struct ModernMealQuickActionButton: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
        let theme: FitGlideTheme.Colors
        @Binding var animateContent: Bool
        let delay: Double
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Text(title)
                    .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onPrimary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                )
            }
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
        }
    }
    
    struct PhotoMealConfirmationDialog: View {
        let photoMealData: PhotoMealData
        let onConfirm: (String, Float, Float, Float, Float, Float) -> Void
        let onDismiss: () -> Void
        let themeColors: FitGlideTheme.Colors
        @State private var mealName: String
        @State private var calories: String
        @State private var protein: String
        @State private var carbs: String
        @State private var fat: String
        @State private var fiber: String
        
        init(
            photoMealData: PhotoMealData,
            onConfirm: @escaping (String, Float, Float, Float, Float, Float) -> Void,
            onDismiss: @escaping () -> Void,
            themeColors: FitGlideTheme.Colors
        ) {
            self.photoMealData = photoMealData
            self.onConfirm = onConfirm
            self.onDismiss = onDismiss
            self.themeColors = themeColors
            self._mealName = State(initialValue: photoMealData.mealName)
            self._calories = State(initialValue: String(photoMealData.calories))
            self._protein = State(initialValue: String(photoMealData.protein))
            self._carbs = State(initialValue: String(photoMealData.carbs))
            self._fat = State(initialValue: String(photoMealData.fat))
            self._fiber = State(initialValue: String(photoMealData.fiber))
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section(header: Text("We detected the following meal from your photo. Please confirm or edit the details.").font(FitGlideTheme.bodyLarge)) {
                        TextField("Meal Name", text: $mealName)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                        TextField("Calories (kcal)", text: $calories)
                            .keyboardType(.decimalPad)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.decimalPad)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                        TextField("Carbs (g)", text: $carbs)
                            .keyboardType(.decimalPad)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                        TextField("Fat (g)", text: $fat)
                            .keyboardType(.decimalPad)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                        TextField("Fiber (g)", text: $fiber)
                            .keyboardType(.decimalPad)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(themeColors.onSurface)
                    }
                }
                .navigationTitle("Confirm Meal")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onDismiss() }
                            .foregroundColor(themeColors.onSurfaceVariant)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            let caloriesFloat = Float(calories) ?? 0
                            let proteinFloat = Float(protein) ?? 0
                            let carbsFloat = Float(carbs) ?? 0
                            let fatFloat = Float(fat) ?? 0
                            let fiberFloat = Float(fiber) ?? 0
                            onConfirm(mealName, caloriesFloat, proteinFloat, carbsFloat, fatFloat, fiberFloat)
                        }
                        .foregroundColor(themeColors.primary)
                    }
                }
                .background(themeColors.background)
            }
        }
    }
    
    // MARK: - Searchable favourite picker
    struct FavoriteFoodSection: View {
        let title: String
        let allFoods: [String]

        @Binding var selected: [String]          // user’s choices
        @State private var query = ""            // search text

        let viewModel: MealsViewModel
        let mealType: MealType
        let colors: FitGlideTheme.Colors
        private let theme = FitGlideTheme.self

        // live-filtered list
        private var matches: [String] {
            query.isEmpty
                ? allFoods
                : allFoods.filter { $0.localizedCaseInsensitiveContains(query) }
        }

        var body: some View {
            Section(                                 // header parameter
                header: Text(title).font(theme.bodyLarge)
            ) {
                // ── search bar ───────────────────────────────────────────
                TextField("Search or add…", text: $query)
                    .textFieldStyle(.roundedBorder)

                // ── filtered results ───────────────────────────────────
                ForEach(matches, id: \.self) { food in
                    HStack {
                        Text(food).font(theme.bodyMedium)
                        Spacer()
                        Image(systemName: selected.contains(food)
                              ? "checkmark.square.fill" : "square")
                            .foregroundColor(colors.primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { toggle(food) }
                }

                // ── add-new option ─────────────────────────────────────
                if shouldShowAddButton {
                    Button(action: { addNew(query) }) {
                        Label("Add \"\(query)\"", systemImage: "plus.circle")
                            .font(theme.bodyMedium)
                    }
                }
            } // <-- Section content closes here
        }     // <-- body closes here

        // MARK: helpers
        private var shouldShowAddButton: Bool {
            !query.isEmpty &&
            !allFoods.contains { $0.compare(query,
                                            options: .caseInsensitive) == .orderedSame }
        }

        private func toggle(_ food: String) {
            if let i = selected.firstIndex(of: food) { selected.remove(at: i) }
            else                                      { selected.append(food) }
        }

        private func addNew(_ name: String) {
            selected.append(name)
            Task { await viewModel.addFavourite(name: name, for: mealType) }
            query = ""
        }
    }
    
    // MARK: - Modern Food Picker Section
    struct ModernFoodPickerSection: View {
        let title: String
        let allFoods: [String]
        @Binding var selected: [String]
        let viewModel: MealsViewModel
        let mealType: MealType
        let colors: FitGlideTheme.Colors
        let animateContent: Bool
        
        @State private var query = ""
        @State private var showSearchResults = false
        
        private var matches: [String] {
            query.isEmpty
                ? allFoods
                : allFoods.filter { $0.localizedCaseInsensitiveContains(query) }
        }
        
        var body: some View {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.onSurface)
                        
                        Text("\(selected.count) items selected")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    // Search Toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSearchResults.toggle()
                        }
                    }) {
                        Image(systemName: showSearchResults ? "xmark.circle.fill" : "magnifyingglass.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.primary)
                    }
                }
                
                // Search Bar
                if showSearchResults {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.onSurfaceVariant)
                        
                        TextField("Search from 600+ Indian foods...", text: $query)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurface)
                        
                        if !query.isEmpty {
                            Button(action: { query = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colors.onSurfaceVariant)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Selected Items
                if !selected.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Selected Items")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                            
                            Button("Clear All") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selected.removeAll()
                                }
                            }
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.primary)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(selected, id: \.self) { food in
                                HStack(spacing: 8) {
                                    Text(food)
                                        .font(FitGlideTheme.caption)
                                        .foregroundColor(colors.onSurface)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selected.removeAll { $0 == food }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(colors.onSurfaceVariant)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colors.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(colors.primary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                
                // Search Results
                if showSearchResults && !query.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Search Results (\(matches.count))")
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(matches.prefix(20), id: \.self) { food in
                                    HStack(spacing: 12) {
                                        Image(systemName: selected.contains(food) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(selected.contains(food) ? colors.primary : colors.onSurfaceVariant)
                                        
                                        Text(food)
                                            .font(FitGlideTheme.bodyMedium)
                                            .foregroundColor(colors.onSurface)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                                                    .background(searchResultBackground(for: food))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            toggle(food)
                                        }
                                    }
                                }
                                
                                // Add new option
                                if shouldShowAddButton {
                                    Button(action: { addNew(query) }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(colors.primary)
                                            
                                            Text("Add \"\(query)\"")
                                                .font(FitGlideTheme.bodyMedium)
                                                .foregroundColor(colors.primary)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(colors.primary.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(colors.primary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                
                // Empty State
                if selected.isEmpty && !showSearchResults {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(colors.onSurfaceVariant)
                        
                        Text("No items selected")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                        
                        Text("Tap the search icon to add your favorite foods")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        
        // MARK: - Helper Methods
        private var shouldShowAddButton: Bool {
            !query.isEmpty &&
            !allFoods.contains { $0.compare(query, options: .caseInsensitive) == .orderedSame }
        }
        
        private func toggle(_ food: String) {
            if let i = selected.firstIndex(of: food) {
                selected.remove(at: i)
            } else {
                selected.append(food)
            }
        }
        
        private func addNew(_ name: String) {
            selected.append(name)
            Task { await viewModel.addFavourite(name: name, for: mealType) }
            query = ""
        }
        
        // MARK: - Helper Views
        private func searchResultBackground(for food: String) -> some View {
            RoundedRectangle(cornerRadius: 8)
                .fill(selected.contains(food) ? colors.primary.opacity(0.1) : colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected.contains(food) ? colors.primary.opacity(0.3) : colors.onSurface.opacity(0.1), lineWidth: 1)
                )
        }
    }

            
            struct MealPickerDialog: View {
                @ObservedObject var viewModel: MealsViewModel
                let mealTypes: [String]
                let onDismiss: () -> Void
                
                // master list of Diet-Component names
                private var allFoods: [String] { viewModel.searchComponents.map(\.name) }
                
                // user selections
                @State private var breakfastFavs: [String] = []
                @State private var lunchFavs:     [String] = []
                @State private var dinnerFavs:    [String] = []
                @State private var snackFavs:     [String] = []
                @State private var mealCount                  = 3
                @State private var selectedTab = 0
                @State private var animateContent = false
                @State private var showIndianWisdom = false
                
                @Environment(\.colorScheme) var colorScheme
                private let theme = FitGlideTheme.self
                private var colors: FitGlideTheme.Colors { theme.colors(for: colorScheme) }
                
                var body: some View {
                    NavigationView {
                        ZStack {
                            // Background with Indian wellness gradient
                            LinearGradient(
                                colors: [
                                    colors.background,
                                    colors.surface.opacity(0.3),
                                    colors.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                            
                            ScrollView {
                                LazyVStack(spacing: 24) {
                                    // Modern Header
                                    modernHeaderSection
                                    
                                    // Indian Wellness Quote
                                    if showIndianWisdom {
                                        indianWellnessQuoteCard
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .move(edge: .top).combined(with: .opacity)
                                            ))
                                    }
                                    
                                    // Diet Preference Card
                                    dietPreferenceCard
                                    
                                    // Meal Planning Tabs
                                    mealPlanningTabs
                                    
                                    // Quick Actions
                                    quickActionsSection
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100)
                            }
                        }
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    onDismiss()
                                }
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save Plan") {
                                    saveMealPlan()
                                }
                                .font(FitGlideTheme.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.primary)
                            }
                        }
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8)) {
                                animateContent = true
                            }
                            
                            // Show Indian wisdom after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showIndianWisdom = true
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Modern Header Section
                var modernHeaderSection: some View {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create Your Diet Plan 🍽️")
                                    .font(FitGlideTheme.titleLarge)
                                    .fontWeight(.bold)
                                    .foregroundColor(colors.onSurface)
                                    .offset(x: animateContent ? 0 : -20)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                
                                Text("Choose from 600+ Indian foods and create your perfect meal plan")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(colors.onSurfaceVariant)
                                    .offset(x: animateContent ? 0 : -20)
                                    .opacity(animateContent ? 1.0 : 0.0)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 16)
                    .background(
                        colors.background
                            .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                }
                
                // MARK: - Indian Wellness Quote Card
                var indianWellnessQuoteCard: some View {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "quote.bubble.fill")
                                .font(.title2)
                                .foregroundColor(colors.primary)
                            
                            Spacer()
                            
                            Text("Indian Wisdom")
                                .font(FitGlideTheme.caption)
                                .fontWeight(.medium)
                                .foregroundColor(colors.onSurfaceVariant)
                        }
                        
                        Text("Annapurna devi ki kripa se, har bhojan mein shakti aur swasthya samaya hai")
                            .font(FitGlideTheme.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(colors.onSurface)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colors.surface)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Diet Preference Card
                var dietPreferenceCard: some View {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.title2)
                                .foregroundColor(colors.primary)
                            
                            Text("Diet Preference")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(mealTypes, id: \.self) { mealType in
                                Button(action: {
                                    Task { await viewModel.setMealType(mealType) }
                                }) {
                                    Text(mealType)
                                        .font(FitGlideTheme.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(viewModel.mealsDataState.mealType == mealType ? colors.onPrimary : colors.onSurface)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(viewModel.mealsDataState.mealType == mealType ? colors.primary : colors.surface)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                }
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: animateContent)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colors.surface)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Meal Planning Tabs
                var mealPlanningTabs: some View {
                    VStack(spacing: 20) {
                        // Tab Selector
                        HStack(spacing: 0) {
                            ForEach(["Breakfast", "Lunch", "Dinner", "Snacks"], id: \.self) { tab in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedTab = ["Breakfast", "Lunch", "Dinner", "Snacks"].firstIndex(of: tab) ?? 0
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab)
                                            .font(FitGlideTheme.bodyMedium)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedTab == ["Breakfast", "Lunch", "Dinner", "Snacks"].firstIndex(of: tab) ? colors.primary : colors.onSurfaceVariant)
                                        
                                        Rectangle()
                                            .fill(selectedTab == ["Breakfast", "Lunch", "Dinner", "Snacks"].firstIndex(of: tab) ? colors.primary : Color.clear)
                                            .frame(height: 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Tab Content
                        TabView(selection: $selectedTab) {
                            ModernFoodPickerSection(
                                title: "Breakfast",
                                allFoods: allFoods,
                                selected: $breakfastFavs,
                                viewModel: viewModel,
                                mealType: .breakfast,
                                colors: colors,
                                animateContent: animateContent
                            )
                            .tag(0)
                            
                            ModernFoodPickerSection(
                                title: "Lunch",
                                allFoods: allFoods,
                                selected: $lunchFavs,
                                viewModel: viewModel,
                                mealType: .lunch,
                                colors: colors,
                                animateContent: animateContent
                            )
                            .tag(1)
                            
                            ModernFoodPickerSection(
                                title: "Dinner",
                                allFoods: allFoods,
                                selected: $dinnerFavs,
                                viewModel: viewModel,
                                mealType: .dinner,
                                colors: colors,
                                animateContent: animateContent
                            )
                            .tag(2)
                            
                            ModernFoodPickerSection(
                                title: "Snacks",
                                allFoods: allFoods,
                                selected: $snackFavs,
                                viewModel: viewModel,
                                mealType: .snack,
                                colors: colors,
                                animateContent: animateContent
                            )
                            .tag(3)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 400)
                    }
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Quick Actions Section
                var quickActionsSection: some View {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Meal Count")
                                .font(FitGlideTheme.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.onSurface)
                            
                            Spacer()
                            
                            Text("\(mealCount) meals/day")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.primary)
                                .fontWeight(.semibold)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(3...6, id: \.self) { count in
                                Button(action: { mealCount = count }) {
                                    Text("\(count)")
                                        .font(FitGlideTheme.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(mealCount == count ? colors.onPrimary : colors.onSurface)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(mealCount == count ? colors.primary : colors.surface)
                                                .overlay(
                                                    Circle()
                                                        .stroke(colors.onSurface.opacity(0.1), lineWidth: 1)
                                                )
                                        )
                                }
                                .scaleEffect(animateContent ? 1.0 : 0.8)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(count - 2) * 0.1), value: animateContent)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colors.surface)
                            .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Save Meal Plan
                private func saveMealPlan() {
                    Task {
                        // ① store the picker settings
                        viewModel.mealsPerDay = mealCount

                        // ② favourites are just a synchronous setter
                        viewModel.applyFavouriteSelections(
                            breakfast: breakfastFavs,
                            lunch:     lunchFavs,
                            dinner:    dinnerFavs,
                            snack:     snackFavs
                        )

                        // ③ build the plan (this one *is* async)
                        await viewModel.generatePlan()

                        onDismiss()
                    }
                }
            }
            
            

        }
    
        

    
    
    // MARK: - Supporting Data Structures
    struct IndianMealCategory: Hashable {
        let title: String
        let icon: String
        let color: Color
    }
    
    struct IndianRecipe: Hashable {
        let title: String
        let calories: Float
        let time: String
        let image: String
    }
    
    struct PhotoMealData: Equatable {
        let mealName: String
        let calories: Float
        let protein: Float
        let carbs: Float
        let fat: Float
        let fiber: Float
    }
    
    // MARK: - Preview
    #Preview {
        let authRepo = AuthRepository()
        let strapiRepo = StrapiRepository(authRepository: authRepo)
        let mealsVM = MealsViewModel(strapi: strapiRepo, auth: authRepo)
        MealsView(viewModel: mealsVM)
        }
    
