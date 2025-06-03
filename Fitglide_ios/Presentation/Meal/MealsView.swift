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
    
    let mealTypes = ["Veg", "Non-Veg", "Mixed"]
    @Environment(\.colorScheme) var colorScheme
    
    private let theme = FitGlideTheme.self
    private let logger = Logger(subsystem: "com.fitglide.meals", category: "MealsView")
    
    init(viewModel: MealsViewModel) {
        self.viewModel     = viewModel
        _selectedDate      = State(initialValue: Date())   // start at today
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading meal data...")
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            } else {
                mainContent
                floatingActionButtons
                overlays
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
        .onAppear {
            guard !viewModel.didInitialize else { return }
            Task {
                await viewModel.setDate(selectedDate)     // <- ensures day-0 diet plan loads
                await viewModel.initializeData()
                await viewModel.fetchRecipes()
            }
        }

        .sheet(isPresented: $showMealPicker) {
            MealPickerDialog(
                viewModel:  viewModel,
                mealTypes:  mealTypes,
                onDismiss: { showMealPicker = false }
            )
        }
        
        .background(theme.colors(for: colorScheme).background)
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                header
                //                Text("Debug BMR: \(Int(viewModel.bmr)) TDEE: \(Int(viewModel.tdee)) mealsDataState.bmr: \(Int(viewModel.mealsDataState.bmr))")
                    .font(theme.bodyMedium)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                dateNavigation
                calorieArc
                macroArcs
                streakIndicator
                bmrCarousel
                currentMeal
                dailySchedule
                dailyQuest
                insights
                recipes
                Spacer()
            }
            .padding()
        }
    }
    
    private var header: some View {
        Text("\(viewModel.firstname.isEmpty ? "Friend" : viewModel.firstname), Kha aur chha!")
            .font(theme.titleLarge)
            .fontWeight(.bold)
            .foregroundColor(theme.colors(for: colorScheme).onBackground)
            .accessibilityLabel("Greeting")
            .accessibilityValue("\(viewModel.firstname), Kha aur chha")
    }
    
    private var dateNavigation: some View {
        HStack {
            Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)! }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            .accessibilityLabel("Previous day")
            Spacer()
            Text(selectedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(theme.titleMedium)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
                .accessibilityLabel("Selected date")
                .accessibilityValue(selectedDate.formatted(.dateTime.month(.abbreviated).day().year()))
            Spacer()
            Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)! }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            .accessibilityLabel("Next day")
        }
        .padding(.horizontal)
    }
    
    private var calorieArc: some View {
        logger.debug("Calorie arc: \(viewModel.mealsDataState.caloriesLogged)/\(viewModel.mealsDataState.bmr)")
        return CalorieArc(
            target: viewModel.mealsDataState.targetKcal,     // 1568 → ring closes
            caloriesLogged: viewModel.mealsDataState.caloriesLogged,
            onTap: { showDetails = true },
            themeColors: theme.colors(for: colorScheme)
        )
        .accessibilityLabel("Calorie intake")
        .accessibilityValue("\(Int(viewModel.mealsDataState.caloriesLogged)) calories out of \(Int(viewModel.mealsDataState.bmr))")
    }
    
    private var macroArcs: some View {
        MacroArcs(
            protein: viewModel.mealsDataState.protein,
            carbs: viewModel.mealsDataState.carbs,
            fat: viewModel.mealsDataState.fat,
            fiber: viewModel.mealsDataState.fiber,
            proteinGoal: viewModel.mealsDataState.proteinGoal,
            carbsGoal: viewModel.mealsDataState.carbsGoal,
            fatGoal: viewModel.mealsDataState.fatGoal,
            fiberGoal: viewModel.mealsDataState.fiberGoal,
            themeColors: theme.colors(for: colorScheme)
        )
    }
    
    private var streakIndicator: some View {
        Group {
            if viewModel.mealsDataState.streak > 0 {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                    Text("Streak: \(viewModel.mealsDataState.streak) days")
                        .font(theme.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                }
                .padding(theme.Button.padding)
                .background(
                    LinearGradient(
                        colors: [theme.colors(for: colorScheme).primary, theme.colors(for: colorScheme).secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.Button.cornerRadius))
                .accessibilityLabel("Streak")
                .accessibilityValue("\(viewModel.mealsDataState.streak) days")
            }
        }
    }
    
    private var bmrCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(bmrOptions, id: \.label) { option in
                    BMRCard(
                        label: option.label,
                        value: option.value,
                        themeColors: theme.colors(for: colorScheme)
                    )
                }
            }
            .padding(.horizontal)
        }
        .accessibilityLabel("BMR options")
    }
    
    private var bmrOptions: [(label: String, value: Float)] {
        [
            ("Maintain", viewModel.mealsDataState.bmr),
            ("Lose @ 0.25 kg/week", viewModel.mealsDataState.bmr - 250),
            ("Lose @ 0.5 kg/week", viewModel.mealsDataState.bmr - 500),
            ("Gain @ 0.25 kg/week", viewModel.mealsDataState.bmr + 250),
            ("Gain @ 0.5 kg/week", viewModel.mealsDataState.bmr + 500)
        ]
    }
    
    private var currentMeal: some View {
        VStack {
            Text("Current Meal")
                .font(theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
            if viewModel.mealsDataState.schedule.allSatisfy({ $0.items.allSatisfy { $0.isConsumed } }) {
                Text("All Meals Done for Today!")
                    .font(theme.bodyMedium)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
                    .padding()
            } else if let currentMeal = viewModel.mealsDataState.currentMeal {
                MealCard(
                    slot: currentMeal,
                    mealIndex: viewModel.mealsDataState.schedule.firstIndex(of: currentMeal) ?? 0,
                    isCurrent: true,
                    favoriteFoods: viewModel.favoriteFoodsState,
                    onToggle: { mealIdx, itemIdx in
                        Task { await viewModel.toggleConsumption(mealIndex: mealIdx, itemIndex: itemIdx) }
                    },
                    onReplace: { mealIdx, itemIdx, newComponentId in
                        Task { await viewModel.replaceMealComponent(mealIndex: mealIdx, itemIndex: itemIdx, newComponentId: newComponentId) }
                    },
                    onSendToCookingBuddy: {
                        Task { await viewModel.sendToCookingBuddy(slot: currentMeal) }
                    },
                    themeColors: theme.colors(for: colorScheme)
                )
            } else {
                Text("No Upcoming Meals Today")
                    .font(theme.bodyMedium)
                    .foregroundColor(theme.colors(for: colorScheme).onSurfaceVariant)
                    .padding()
            }
        }
    }
    
    private var dailySchedule: some View {
        VStack {
            Text("Day’s Schedule")
                .font(theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
            let filteredSchedule = viewModel.mealsDataState.schedule.filter {
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
            }
            DailySchedule(
                schedule: filteredSchedule,
                viewModel: viewModel,
                currentMeal: viewModel.mealsDataState.currentMeal,
                onMealClick: { slot in
                    Task {
                        let updatedSchedule = viewModel.mealsDataState.schedule.map { $0.id == slot.id ? slot : $0 }
                        await viewModel.updateCurrentMeal(schedule: updatedSchedule)
                    }
                },
                themeColors: theme.colors(for: colorScheme)
            )
        }
    }
    
    private var dailyQuest: some View {
        logger.debug("Macro goals: protein=\(viewModel.mealsDataState.protein)/\(viewModel.mealsDataState.proteinGoal), carbs=\(viewModel.mealsDataState.carbs)/\(viewModel.mealsDataState.carbsGoal), fat=\(viewModel.mealsDataState.fat)/\(viewModel.mealsDataState.fatGoal), fiber=\(viewModel.mealsDataState.fiber)/\(viewModel.mealsDataState.fiberGoal)")
        return VStack {
            Text("Daily Quest")
                .font(theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    QuestCard(
                        macro: "Protein",
                        progress: viewModel.mealsDataState.protein,
                        max: viewModel.mealsDataState.proteinGoal,
                        themeColors: theme.colors(for: colorScheme)
                    )
                    QuestCard(
                        macro: "Carbs",
                        progress: viewModel.mealsDataState.carbs,
                        max: viewModel.mealsDataState.carbsGoal,
                        themeColors: theme.colors(for: colorScheme)
                    )
                    QuestCard(
                        macro: "Fat",
                        progress: viewModel.mealsDataState.fat,
                        max: viewModel.mealsDataState.fatGoal,
                        themeColors: theme.colors(for: colorScheme)
                    )
                    QuestCard(
                        macro: "Fiber",
                        progress: viewModel.mealsDataState.fiber,
                        max: viewModel.mealsDataState.fiberGoal,
                        themeColors: theme.colors(for: colorScheme)
                    )
                }
                .padding(.horizontal)
            }
        }
        .accessibilityLabel("Daily quest")
    }
    
    private var insights: some View {
        VStack {
            Text("Insights")
                .font(theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
            Button(action: { showWeeklyInsights = true }) {
                Text("View your weekly meal insights")
                    .font(theme.bodyMedium)
                    .foregroundColor(theme.colors(for: colorScheme).onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(theme.Button.padding)
                    .background(theme.colors(for: colorScheme).surfaceVariant.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: theme.Button.cornerRadius))
            }
        }
    }
    
    private var recipes: some View {
        VStack {
            Text("Recipes")
                .font(theme.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(theme.colors(for: colorScheme).onBackground)
            RecipeCarousel(viewModel: viewModel, themeColors: theme.colors(for: colorScheme))
        }
    }
    
    private var floatingActionButtons: some View {
        VStack {
            HStack {
                Button(action: { showPhotoPicker = true }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                        .frame(width: 48, height: 48)
                        .background(theme.colors(for: colorScheme).primary)
                        .clipShape(Circle())
                }
                .padding([.top, .leading], 16)
                .accessibilityLabel("Take meal photo")
                .accessibilityHint("Opens the camera to capture a meal photo")
                Spacer()
                Button(action: { showMealPicker = true }) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                        .frame(width: 48, height: 48)
                        .background(theme.colors(for: colorScheme).secondary)
                        .clipShape(Circle())
                }
                .padding([.top, .trailing], 16)
                .accessibilityLabel("Pick meal")
                .accessibilityHint("Opens the meal picker dialog")
            }
            Spacer()
            Button(action: { showMealPicker = true }) {
                Image(systemName: "plus")
                    .foregroundColor(theme.colors(for: colorScheme).onPrimary)
                    .frame(width: 56, height: 56)
                    .background(theme.colors(for: colorScheme).tertiary)
                    .clipShape(Circle())
            }
            .padding(.bottom, 16)
            .padding(.trailing, 16)
            .accessibilityLabel("Create diet plan")
            .accessibilityHint("Opens the diet plan creation dialog")
        }
    }
    
    private var overlays: some View {
        Group {
            if showDetails {
                MealsDetailsOverlay(
                    mealsData: viewModel.mealsDataState,
                    onDismiss: { showDetails = false },
                    themeColors: theme.colors(for: colorScheme)
                )
            }
            if showWeeklyInsights {
                WeeklyInsightsOverlay(
                    mealsData: viewModel.mealsDataState,
                    onDismiss: { showWeeklyInsights = false },
                    themeColors: theme.colors(for: colorScheme)
                )
            }
            if isProcessingPhoto {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .foregroundColor(theme.colors(for: colorScheme).primary)
            }
            if showPhotoConfirmation, let photoMealData = photoMealData {
                PhotoMealConfirmationDialog(
                    photoMealData: photoMealData,
                    onConfirm: { mealName, calories, protein, carbs, fat, fiber in
                        Task {
                            await viewModel.logPhotoMeal(mealName: mealName, calories: calories, protein: protein, carbs: carbs, fat: fat, fiber: fiber)
                            showPhotoConfirmation = false
                            self.photoMealData = nil
                        }
                    },
                    onDismiss: {
                        showPhotoConfirmation = false
                        self.photoMealData = nil
                    },
                    themeColors: theme.colors(for: colorScheme)
                )
            }
        }
    }
    
    
    struct CalorieArc: View {
        let target: Float
        let caloriesLogged: Float
        let onTap: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack {
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(caloriesLogged / max(target, 1), 1))) // Avoid division by zero
                        .stroke(target > 0 && caloriesLogged > 0 ? themeColors.primary : themeColors.onSurfaceVariant, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(caloriesLogged))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(themeColors.onSurface)
                }
                .onTapGesture(perform: onTap)
                Text("Intake (Kcal)")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
            }
        }
    }
    
    struct MacroArcs: View {
        let protein: Float
        let carbs: Float
        let fat: Float
        let fiber: Float
        let proteinGoal: Float // Added
        let carbsGoal: Float
        let fatGoal: Float
        let fiberGoal: Float
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            HStack(spacing: 16) {
                MacroArc(label: "Protein", value: protein, max: proteinGoal, color: protein > 0 ? themeColors.primary : themeColors.onSurfaceVariant, themeColors: themeColors)
                MacroArc(label: "Carbs", value: carbs, max: carbsGoal, color: carbs > 0 ? themeColors.secondary : themeColors.onSurfaceVariant, themeColors: themeColors)
                MacroArc(label: "Fat", value: fat, max: fatGoal, color: fat > 0 ? themeColors.tertiary : themeColors.onSurfaceVariant, themeColors: themeColors)
                MacroArc(label: "Fiber", value: fiber, max: fiberGoal, color: fiber > 0 ? themeColors.quaternary : themeColors.onSurfaceVariant, themeColors: themeColors)
            }
        }
    }
    
    struct MacroArc: View {
        let label: String
        let value: Float
        let max: Float
        let color: Color
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack {
                ZStack {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(value / Swift.max(max, 1), 1))) // Avoid division by zero
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(value))g")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(themeColors.onSurface)
                }
                Text(label)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
            }
            .accessibilityLabel("\(label) intake")
            .accessibilityValue("\(Int(value)) grams out of \(Int(max))")
        }
    }
    
    struct BMRCard: View {
        let label: String
        let value: Float
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack {
                Text("\(Int(value)) Kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                Text(label)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
            }
            .frame(width: 200)
            .padding(8)
            .background(themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                    .stroke(themeColors.onSurface.opacity(0.2), lineWidth: 2)
            )
            .shadow(radius: FitGlideTheme.Card.elevation)
        }
    }
    
    struct QuestCard: View {
        let macro: String
        let progress: Float
        let max: Float
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            Logger().debug("Rendering \(macro): \(progress)/\(max)")
            return VStack {
                Text("\(macro) Goal")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                ProgressView(value: max > 0 ? min(progress / max, 1) : 0)
                    .progressViewStyle(.linear)
                    .accentColor(themeColors.primary)
                Text("\(Int(progress))g / \(Int(max))g")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
            }
            .frame(width: 200)
            .padding(8)
            .background(themeColors.surfaceVariant.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .padding(.vertical, 8)
            .shadow(radius: FitGlideTheme.Card.elevation)
            .accessibilityLabel("\(macro) goal")
            .accessibilityValue("\(Int(progress)) grams out of \(Int(max))")
        }
    }
    
    struct DailySchedule: View {
        let schedule: [MealSlot]
        let viewModel: MealsViewModel
        let currentMeal: MealSlot?
        let onMealClick: (MealSlot) -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            LazyVStack(spacing: 4) {
                ForEach(schedule) { slot in
                    Button(action: { onMealClick(slot) }) {
                        HStack {
                            Image(systemName: slot.type == "Breakfast" || slot.type == "Lunch" ? "sun.max.fill" : slot.type == "Dinner" ? "moon.fill" : "fork.knife")
                                .foregroundColor(themeColors.primary)
                            Text("\(slot.type) - \(slot.time)")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(themeColors.onSurface)
                            Spacer()
                            Text(slot.items.allSatisfy { $0.isConsumed } ? "Consumed" : "Pending")
                                .font(FitGlideTheme.caption)
                                .foregroundColor(slot.items.allSatisfy { $0.isConsumed } ? themeColors.primary : themeColors.secondary)
                        }
                        .padding(8)
                        .background(slot == currentMeal || slot.items.allSatisfy { $0.isConsumed } ? themeColors.surfaceVariant.opacity(0.8) : themeColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .frame(height: 100)
            .accessibilityLabel("Daily schedule")
        }
    }
    
    struct MealCard: View {
        let slot: MealSlot
        let mealIndex: Int
        let isCurrent: Bool
        let favoriteFoods: [String]
        let onToggle: (Int, Int) -> Void
        let onReplace: (Int, Int, String) -> Void
        let onSendToCookingBuddy: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            MealCardContent(
                slot: slot,
                mealIndex: mealIndex,
                favoriteFoods: favoriteFoods,
                onToggle: onToggle,
                onReplace: onReplace,
                onSendToCookingBuddy: onSendToCookingBuddy,
                themeColors: themeColors
            )
            .padding(16)
            .background(slot.isMissed ? themeColors.surfaceVariant.opacity(0.8) : themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                    .stroke(isCurrent ? themeColors.secondary : themeColors.primary, lineWidth: 2)
            )
            .padding(.vertical, 8)
            .shadow(radius: FitGlideTheme.Card.elevation)
        }
    }
    
    struct MealCardContent: View {
        let slot: MealSlot
        let mealIndex: Int
        let favoriteFoods: [String]
        let onToggle: (Int, Int) -> Void
        let onReplace: (Int, Int, String) -> Void
        let onSendToCookingBuddy: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                MealCardHeader(slot: slot, themeColors: themeColors)
                ForEach(slot.items.indices, id: \.self) { itemIndex in
                    MealItemRow(
                        item: slot.items[itemIndex],
                        mealIndex: mealIndex,
                        itemIndex: itemIndex,
                        allFoods: favoriteFoods,
                        onToggle: onToggle,
                        onReplace: onReplace,
                        themeColors: themeColors
                    )
                }
                MealCardFooter(slot: slot, onSendToCookingBuddy: onSendToCookingBuddy, themeColors: themeColors)
            }
        }
    }
    
    struct MealCardHeader: View {
        let slot: MealSlot
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            HStack {
                Image(systemName: slot.type == "Breakfast" || slot.type == "Lunch" ? "sun.max.fill" : slot.type == "Dinner" ? "moon.fill" : "fork.knife")
                    .foregroundColor(themeColors.primary)
                    .frame(width: 36, height: 36)
                Text("\(slot.type) - \(slot.time)")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                Spacer()
            }
        }
    }
    
    struct MealCardFooter: View {
        let slot: MealSlot
        let onSendToCookingBuddy: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Int(slot.calories)) Kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurfaceVariant)
                Text("P: \(Int(slot.protein))g, C: \(Int(slot.carbs))g, F: \(Int(slot.fat))g, Fib: \(Int(slot.fiber))g")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
                Button(action: onSendToCookingBuddy) {
                    Text("Send to Your Cooking Buddy")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(themeColors.onPrimary)
                        .padding(FitGlideTheme.Button.padding)
                        .background(themeColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
                }
            }
        }
    }
    
    struct MealItemRow: View {
        // MARK: Inputs
        let item: MealItem
        let mealIndex: Int
        let itemIndex: Int
        let allFoods: [String]               // <-- renamed: full catalogue
        let onToggle: (Int, Int) -> Void
        let onReplace: (Int, Int, String) -> Void
        let themeColors: FitGlideTheme.Colors
        
        // MARK: Local state
        @State private var searchQuery = ""
        
        // MARK: Helpers ---------------------------------------------------------
        /// Units that represent weight – we show those as whole-number g/kg/mg
        private let weightUnits: Set<String> = ["g", "gm", "kg", "mg"]
        
        private var quantityText: String {
            let u = item.unit.trimmingCharacters(in: .whitespaces)
            // weight → whole Int
            if weightUnits.contains(u.lowercased()) {
                return "\(Int(item.servingSize)) \(u)"
            }
            // non-weight → 1-dec place if needed
            let qty = item.servingSize
            let qtyString = qty == floor(qty)
                ? String(format: "%.0f", qty)
                : String(format: "%.1f", qty)
            // crude pluraliser
            let pluralUnit = (qty == 1) || u.hasSuffix("s") ? u : u + "s"
            return "\(qtyString) \(pluralUnit)"
        }
        
        // MARK: UI --------------------------------------------------------------
        var body: some View {
            HStack {
                Text(item.name)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(item.calories)) kcal")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
                    .padding(.horizontal, 8)
                
                Text(quantityText)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
                    .padding(.horizontal, 8)
                
                Toggle(
                    isOn: Binding(
                        get: { item.isConsumed },
                        set: { _ in onToggle(mealIndex, itemIndex) }
                    )
                ) {
                    EmptyView()
                }
                .toggleStyle(CheckboxToggleStyle(themeColors: themeColors))
                .frame(width: 24, height: 24)
                .padding(.trailing, 12)
                
                // ───────── Replace menu ─────────
                Menu {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    ForEach(
                        allFoods.filter {
                            searchQuery.isEmpty ||
                            $0.lowercased().contains(searchQuery.lowercased())
                        },
                        id: \.self
                    ) { food in
                        Button(food) {
                            onReplace(mealIndex, itemIndex, food)
                            Logger().debug("Replace → \(food)")
                            searchQuery = ""
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeColors.onSurfaceVariant)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.vertical, 6)
        }
    }

    struct CheckboxToggleStyle: ToggleStyle {
        let themeColors: FitGlideTheme.Colors
        
        func makeBody(configuration: Configuration) -> some View {
            Button(action: { configuration.isOn.toggle() }) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? themeColors.primary : themeColors.onSurfaceVariant)
            }
        }
    }
    
    struct RecipeCarousel: View {
        @ObservedObject var viewModel: MealsViewModel
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(viewModel.mealsDataState.recipes, id: \.id) { component in
                        RecipeCard(component: component, themeColors: themeColors)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
    
    struct RecipeCard: View {
        let component: DietComponentCard
        let themeColors: FitGlideTheme.Colors
        @State private var showDetailsPopup = false
        
        var body: some View {
            VStack {
                Text(component.name)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(themeColors.onSurface)
                    .lineLimit(1)
                Text("\(component.calories) Kcal")
                    .font(FitGlideTheme.caption)
                    .foregroundColor(themeColors.onSurfaceVariant)
            }
            .frame(width: 200, height: 120)
            .padding(12)
            .background(themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(radius: FitGlideTheme.Card.elevation)
            .padding(4)
            .onTapGesture { showDetailsPopup = true }
            .sheet(isPresented: $showDetailsPopup) {
                RecipeDetailsPopup(component: component, onDismiss: { showDetailsPopup = false }, themeColors: themeColors)
            }
        }
    }
    
    struct RecipeDetailsPopup: View {
        let component: DietComponentCard
        let onDismiss: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 16) {
                    Text(component.name)
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(themeColors.onSurface)
                        .padding(.bottom, 8)
                    VStack(spacing: 16) {
                        Text("\(component.calories) Kcal")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(themeColors.primary)
                        HStack {
                            MacroDetail(label: "Protein", value: component.protein, accentColor: themeColors.secondary, themeColors: themeColors)
                            MacroDetail(label: "Carbs", value: component.carbs, accentColor: themeColors.tertiary, themeColors: themeColors)
                        }
                        HStack {
                            MacroDetail(label: "Fat", value: component.fat, accentColor: themeColors.secondary, themeColors: themeColors)
                            MacroDetail(label: "Fiber", value: component.fiber, accentColor: themeColors.quaternary, themeColors: themeColors)
                        }
                    }
                    .padding()
                    .background(themeColors.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    Text("Tap anywhere to close")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(themeColors.onSurfaceVariant)
                        .italic()
                    Spacer()
                }
                .padding()
                .background(themeColors.background)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Close") { onDismiss() }
                            .foregroundColor(themeColors.primary)
                    }
                }
                .onTapGesture { onDismiss() }
            }
        }
    }
    
    struct MacroDetail: View {
        let label: String
        let value: String
        let accentColor: Color
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            VStack {
                Text(label)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurfaceVariant)
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
            }
            .padding(8)
            .background(themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .padding(4)
        }
    }
    
    struct MealsDetailsOverlay: View {
        let mealsData: MealsData
        let onDismiss: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack(spacing: 16) {
                Text("Meal Details")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                Text("BMR: \(Int(mealsData.bmr)) Kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Logged: \(Int(mealsData.caloriesLogged)) Kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Protein: \(Int(mealsData.protein))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Carbs: \(Int(mealsData.carbs))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Fat: \(Int(mealsData.fat))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Fiber: \(Int(mealsData.fiber))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
            }
            .padding(20)
            .background(themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .padding()
            .shadow(radius: FitGlideTheme.Card.elevation)
        }
    }
    
    struct WeeklyInsightsOverlay: View {
        let mealsData: MealsData
        let onDismiss: () -> Void
        let themeColors: FitGlideTheme.Colors
        
        var body: some View {
            let weeklyData = MealsView.calculateWeeklyData(mealsData: mealsData)
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack(spacing: 16) {
                Text("Weekly Meal Insights")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                Text("Average Daily Intake:")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                Text("Calories: \(Int(weeklyData.averageCalories)) kcal")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Protein: \(Int(weeklyData.averageProtein))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Carbs: \(Int(weeklyData.averageCarbs))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Fat: \(Int(weeklyData.averageFat))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Fiber: \(Int(weeklyData.averageFiber))g")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurface)
                Text("Graphs: Coming Soon!")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(themeColors.onSurfaceVariant)
                    .padding(8)
                Text("Insights:")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(themeColors.onSurface)
                if weeklyData.averageProtein < mealsData.proteinGoal * 0.8 {
                    Text("You're low on protein this week (\(Int(weeklyData.averageProtein))g vs goal \(Int(mealsData.proteinGoal))g). Consider adding more protein-rich foods like chicken or lentils.")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(themeColors.onSurface)
                } else {
                    Text("Great job! You're meeting your protein goal this week.")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(themeColors.onSurface)
                }
                if weeklyData.averageCalories > mealsData.bmr * 1.2 {
                    Text("Your calorie intake (\(Int(weeklyData.averageCalories)) kcal) is higher than your BMR (\(Int(mealsData.bmr)) kcal). If weight loss is your goal, consider reducing portion sizes.")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(themeColors.onSurface)
                }
            }
            .padding(20)
            .background(themeColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .padding()
            .shadow(radius: FitGlideTheme.Card.elevation)
        }
    }
    
    struct WeeklyMealData {
        let averageCalories: Float
        let averageProtein: Float
        let averageCarbs: Float
        let averageFat: Float
        let averageFiber: Float
    }
    
    func calculateWeeklyData(mealsData: MealsData) -> WeeklyMealData {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!
        let weeklyMeals = mealsData.schedule.filter { meal in
            meal.date >= startDate && meal.date <= endDate
        }
        
        if weeklyMeals.isEmpty {
            return WeeklyMealData(averageCalories: 0, averageProtein: 0, averageCarbs: 0, averageFat: 0, averageFiber: 0)
        }
        
        let totalCalories = weeklyMeals.reduce(0) { total, mealSlot in
            total + mealSlot.items.filter { $0.isConsumed }.reduce(0) { subtotal, item in
                subtotal + item.calories
            }
        }
        let totalProtein = weeklyMeals.reduce(0) { $0 + $1.protein }
        let totalCarbs = weeklyMeals.reduce(0) { $0 + $1.carbs }
        let totalFat = weeklyMeals.reduce(0) { $0 + $1.fat }
        let totalFiber = weeklyMeals.reduce(0) { $0 + $1.fiber }
        
        let daysWithData = Set(weeklyMeals.map { Calendar.current.startOfDay(for: $0.date) }).count
        let days = max(daysWithData, 1)
        
        return WeeklyMealData(
            averageCalories: totalCalories / Float(days),
            averageProtein: totalProtein / Float(days),
            averageCarbs: totalCarbs / Float(days),
            averageFat: totalFat / Float(days),
            averageFiber: totalFiber / Float(days)
        )
    }
    
    struct PhotoMealData: Equatable {
        let mealName: String
        let calories: Float
        let protein: Float
        let carbs: Float
        let fat: Float
        let fiber: Float
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
                
                @Environment(\.colorScheme) var colorScheme
                private let theme = FitGlideTheme.self
                
                var body: some View {
                    NavigationStack {
                        Form {
                            // ── Diet preference ────────────────────────────────────────────
                            Section(
                                header: Text("Diet Preference").font(theme.bodyLarge)
                            ) {
                                Picker("Diet Preference",
                                       selection: Binding(
                                        get: { viewModel.mealsDataState.mealType },
                                        set: { newVal in Task { await viewModel.setMealType(newVal) } }
                                       )
                                ) {
                                    ForEach(mealTypes, id: \.self) { Text($0).tag($0) }
                                }
                                .pickerStyle(.menu)
                            }
                            
                            // ── Searchable favourite lists ───────────────────────────────
                            FavoriteFoodSection(
                                title:      "Breakfast",
                                allFoods:   allFoods,
                                selected:   $breakfastFavs,
                                viewModel:  viewModel,
                                mealType:   .breakfast,
                                colors:     theme.colors(for: colorScheme)
                            )
                            
                            FavoriteFoodSection(
                                title:    "Lunch",
                                allFoods: allFoods,
                                selected: $lunchFavs,
                                viewModel: viewModel,
                                mealType: .lunch,
                                colors:   theme.colors(for: colorScheme)
                            )
                            
                            FavoriteFoodSection(
                                title:    "Dinner",
                                allFoods: allFoods,
                                selected: $dinnerFavs,
                                viewModel: viewModel,
                                mealType: .dinner,
                                colors:   theme.colors(for: colorScheme)
                            )
                            
                            FavoriteFoodSection(
                                title:    "Snacks (optional)",
                                allFoods: allFoods,
                                selected: $snackFavs,
                                viewModel: viewModel,
                                mealType: .snack,
                                colors:   theme.colors(for: colorScheme)
                            )
                            
                            // ── meal count ───────────────────────────────────────────────
                            Section(
                                header: Text("Number of Meals (Suggested: 3-6)")
                                    .font(theme.bodyLarge)
                            ) {
                                Picker("Meals", selection: $mealCount) {
                                    ForEach(3...6, id: \.self) { Text("\($0)") }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .navigationTitle("Set Up Your Diet Plan")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", action: onDismiss)
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    Task {
                                        // ① store the picker settings  ──────────────
                                        viewModel.mealsPerDay = mealCount         // ← stays sync

                                        // ② favourites are just a synchronous setter
                                        viewModel.applyFavouriteSelections(       // ← no await
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
                    }
                }
            }
            
            
            struct MealsView_Previews: PreviewProvider {
                static var previews: some View {
                    MealsView(
                        viewModel: MealsViewModel(
                            strapi: StrapiRepository(
                                api: StrapiApiClient(),
                                authRepository: AuthRepository()
                            ),
                            auth: AuthRepository()
                        )
                    )
                    .previewDisplayName("Meals View")
                    .previewDevice(PreviewDevice(rawValue: "iPhone 15"))
                }
            }
        }
    
        
        extension MealsView {
            /// Computes 7-day averages for calories & macros
            static func calculateWeeklyData(mealsData: MealsData) -> WeeklyMealData {
                let endDate   = Date()
                let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!
                
                let weeklySlots = mealsData.schedule.filter { slot in
                    slot.date >= startDate && slot.date <= endDate
                }
                
                guard !weeklySlots.isEmpty else {
                    return WeeklyMealData(averageCalories: 0, averageProtein: 0,
                                          averageCarbs: 0, averageFat: 0, averageFiber: 0)
                }
                
                let totalCalories = weeklySlots.reduce(0) { total, slot in
                    total + slot.items.filter(\.isConsumed).reduce(0) { $0 + $1.calories }
                }
                let totalProtein = weeklySlots.reduce(0) { $0 + $1.protein }
                let totalCarbs   = weeklySlots.reduce(0) { $0 + $1.carbs }
                let totalFat     = weeklySlots.reduce(0) { $0 + $1.fat }
                let totalFiber   = weeklySlots.reduce(0) { $0 + $1.fiber }
                
                let dayCount = max(Set(weeklySlots.map { Calendar.current.startOfDay(for: $0.date) }).count, 1)
                
                return WeeklyMealData(
                    averageCalories: totalCalories / Float(dayCount),
                    averageProtein:  totalProtein  / Float(dayCount),
                    averageCarbs:    totalCarbs    / Float(dayCount),
                    averageFat:      totalFat      / Float(dayCount),
                    averageFiber:    totalFiber    / Float(dayCount)
                )
            }
        }
    
