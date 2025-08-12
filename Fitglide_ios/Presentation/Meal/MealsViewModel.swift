//
//  MealsViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/06/25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

actor MealsDataStore {
    var mealsData: MealsData
    var dailyLogIds: [Date: String?] = [:]
    
    init(mealsData: MealsData) {
        self.mealsData = mealsData
    }
    
    func updateMealsData(_ newData: MealsData) {
        self.mealsData = newData
    }
    
    func updateDailyLogId(for date: Date, id: String?) {
        self.dailyLogIds[Calendar.current.startOfDay(for: date)] = id
    }
    
    func getDailyLogId(for date: Date) -> String? {
        self.dailyLogIds[Calendar.current.startOfDay(for: date)] ?? nil
    }

}

@MainActor
class MealsViewModel: ObservableObject {
    var didInitialize = false
    @Published var mealsDataState: MealsData
    @Published var favoriteFoodsState: [String] = []
    @Published var searchComponents: [DietComponentEntry] = []
    @Published var firstname: String = "User"
    private var componentsCache: [String: DietComponentEntry] = [:]
    private let dataStore: MealsDataStore
    private let strapi: StrapiRepository
    private let auth: AuthRepository
    private let logger = Logger(subsystem: "com.fitglide.meals", category: "MealsViewModel")
    var mealsPerDay: Int = 3
    private var favoriteSelections: [MealType: [String]] = [:]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    init(strapi: StrapiRepository = StrapiRepository(api: StrapiApiClient(), authRepository: AuthRepository()), auth: AuthRepository = AuthRepository()) {
        self.strapi = strapi
        self.auth = auth
        self.firstname = auth.authState.firstName ?? "User"
        let initialMealsData = MealsData(
            bmr: 1800,
            caloriesLogged: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            schedule: [],
            currentMeal: nil,
            streak: 0,
            questActive: false,
            questGoal: "Protein",
            questProgress: 0,
            questTarget: 80,
            selectedDate: Date(),
            mealType: "Veg",
            favoriteFood: "",
            customMealRequested: false,
            customMealMessage: "",
            hasDietPlan: false,
            recipes: [],
            proteinGoal: 0,
            carbsGoal: 0,
            targetKcal: 1800,
            fatGoal: 0,
            fiberGoal: 0
        )
        self.mealsDataState = initialMealsData
        self.dataStore = MealsDataStore(mealsData: initialMealsData)
    }
    
    private func parseMacro(_ value: String?) -> Float {
        guard let str = value else { return 0 }
        return str.replacingOccurrences(of: "g", with: "").floatValue ?? 0
    }

    
    func initializeData() async {
        if didInitialize { return }
        didInitialize = true

        do {
            let profile = try await strapi.getUserProfile()
            await MainActor.run {
                self.firstname = profile.firstName ?? "User"
            }
        } catch {
            logger.error("Error fetching user profile: \(error.localizedDescription)")
        }

        async let _ = fetchMealsData(date: mealsDataState.selectedDate)
        async let _ = fetchAllDietComponents()
        async let _ = calculateStreak()
        async let _ = fetchRecipes() // Ensure recipes are fetched on initialization
    }

    func fetchAllDietComponents() async {
        do {
            guard auth.authState.jwt != nil else {
                logger.error("Missing token")
                return
            }
            let maxAttempts = 3
            var attempts = 0
            while attempts < maxAttempts {
                do {
                    let response = try await strapi.getDietComponents(type: mealsDataState.mealType)
                    let components = response.data
                    await MainActor.run {
                        components.forEach { component in
                            if let id = component.documentId {
                                self.componentsCache[id] = component
                            }
                        }
                        self.searchComponents   = components
                        self.favoriteFoodsState = components.compactMap { $0.name }
                        self.logger.debug("Fetched \(components.count) diet components")
                    }
                    return
                } catch {
                    logger.warning("Fetch attempt \(attempts + 1) failed: \(error.localizedDescription)")
                    attempts += 1
                    if attempts < maxAttempts {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                }
            }
            logger.error("Failed to fetch diet components after \(maxAttempts) attempts")
        } catch {
            logger.error("Error fetching diet components: \(error.localizedDescription)")
        }
    }
    
    func fetchMealsData(date: Date) async {
        do {
            guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
                logger.error("Missing userId or token")
                return
            }
            let dateStr = dateFormatter.string(from: date)
            let healthVitals = try await strapi.getHealthVitals(userId: userId)
            let vitals = healthVitals.data.first
            let bmr = Float(vitals?.calorieGoal ?? 1800)
            let strategy = vitals?.weight_loss_strategy ?? "Maintain"
            let age = calculateAge(from: vitals?.date_of_birth)
            let bmi = vitals?.BMI ?? 25.0
            let tdee = calculateTDEE(bmr: bmr, activityLevel: vitals?.activity_level, age: age, bmi: bmi)
            let calorieAdjustment = calorieAdjustment(for: strategy)
            let targetKcal = tdee + calorieAdjustment
            
            let dietPlanResponse = try await strapi.getDietPlan(userId: userId, date: date)
            let activePlan       = dietPlanResponse.data.first(where: \.active)

            
            let dietLogs = try await strapi.getDietLogs(userId: userId, dateString: dateStr)
            let existingLog = dietLogs.data.max(by: { $0.documentId < $1.documentId })
            await dataStore.updateDailyLogId(for: date, id: existingLog?.documentId)
            
            var totalProteinGoal: Float = 0
            var totalCarbsGoal: Float = 0
            var totalFatGoal: Float = 0
            var totalFiberGoal: Float = 0
            var schedule: [MealSlot] = []
            
            var mealLogMap: [String: [ComponentLogEntry]] = [:]
            if let meals = existingLog?.meals {
                mealLogMap = meals.reduce(into: [:]) { result, meal in
                    result[meal.mealId] = meal.components
                }
            }
            
            if let activePlan, !(activePlan.meals?.isEmpty ?? true) {
                schedule = activePlan.meals?.filter { $0.mealDate == dateStr }.map { meal in
                    let displayTime = isoToDisplayTime(meal.mealTime)
                    let loggedComponents = mealLogMap[meal.documentId] ?? []
                    let components = meal.dietComponents?.compactMap { component -> MealItem? in
                        if let id = component.documentId { self.componentsCache[id] = component }
                        let isConsumed = loggedComponents.first { $0.componentId == component.documentId }?.consumed ?? false
                        return MealItem(
                            id: component.documentId ?? UUID().uuidString,      // fallback id
                            name: component.name,
                            servingSize: Float(component.portionSize ?? 100),
                            calories: Float(component.calories ?? 0),
                            unit: component.unit ?? "Serving",                  // <- no optional
                            isConsumed: isConsumed,
                            imageUrl: component.recipeUrl
                        )
                    } ?? [MealItem(
                        id: meal.documentId,
                        name: meal.name,
                        servingSize: Float(meal.basePortion),
                        calories: Float(meal.totalCalories),
                        unit: "Serving",                                       // <- replaced
                        isConsumed: false,
                        imageUrl: nil
                    )]

                    let mealProtein = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) }
                    let mealCarbs = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) }
                    let mealFat = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) }
                    let mealFiber = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) }
                    
                    totalProteinGoal += mealProtein
                    totalCarbsGoal += mealCarbs
                    totalFatGoal += mealFat
                    totalFiberGoal += mealFiber
                    
                    let missed = (DateFormatter.timeFormatter.date(from: displayTime)?.isBeforeNow ?? false) && components.contains { !$0.isConsumed }
                    return MealSlot(
                        id: meal.documentId,
                        type: meal.name.replacingOccurrences(of: " Meal", with: ""),
                        time: displayTime,
                        items: components,
                        calories: components.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories },
                        protein: mealProtein,
                        carbs: mealCarbs,
                        fat: mealFat,
                        fiber: mealFiber,
                        date: date,
                        isMissed: missed,
                        targetCalories: Float(meal.totalCalories)
                    )
                } ?? []
                
                if schedule.isEmpty, let meals = activePlan.meals {
                    schedule = meals.map { meal in
                        let displayTime = isoToDisplayTime(meal.mealTime)
                        let loggedComponents = mealLogMap[meal.documentId] ?? []
                        let components = meal.dietComponents?.compactMap { component -> MealItem? in
                            if let id = component.documentId { self.componentsCache[id] = component }

                            let isConsumed = loggedComponents.first { $0.componentId == component.documentId }?.consumed ?? false
                            return MealItem(
                                id: component.documentId ?? UUID().uuidString,
                                name: component.name,
                                servingSize: Float(component.portionSize ?? 100),
                                calories: Float(component.calories ?? 0),
                                unit: component.unit ?? "Serving",
                                isConsumed: isConsumed,
                                imageUrl: component.recipeUrl
                            )
                        } ?? [MealItem(
                            id: meal.documentId,
                            name: meal.name,
                            servingSize: Float(meal.basePortion),
                            calories: Float(meal.totalCalories),
                            unit: "Serving",
                            isConsumed: false,
                            imageUrl: nil
                        )]

                        let mealProtein = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) }
                        let mealCarbs = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) }
                        let mealFat = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) }
                        let mealFiber = components.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) }
                        
                        totalProteinGoal += mealProtein
                        totalCarbsGoal += mealCarbs
                        totalFatGoal += mealFat
                        totalFiberGoal += mealFiber
                        
                        let missed = (DateFormatter.timeFormatter.date(from: displayTime)?.isBeforeNow ?? false) && components.contains { !$0.isConsumed }
                        return MealSlot(
                            id: meal.documentId,
                            type: meal.name.replacingOccurrences(of: " Meal", with: ""),
                            time: displayTime,
                            items: components,
                            calories: components.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories },
                            protein: mealProtein,
                            carbs: mealCarbs,
                            fat: mealFat,
                            fiber: mealFiber,
                            date: date,
                            isMissed: missed,
                            targetCalories: Float(meal.totalCalories)
                        )
                    }
                }
                
                if await dataStore.getDailyLogId(for: date) == nil {
                    let dietLogRequest = DietLogRequest(
                        date: dateStr,
                        usersPermissionsUser: UserId(id: userId),
                        meals: schedule.map { meal in
                            MealLogEntry(
                                mealId: meal.id,
                                components: meal.items.map { ComponentLogEntry(componentId: $0.id, consumed: $0.isConsumed) }
                            )
                        }
                    )
                    let logResponse = try await strapi.postDietLog(body: dietLogRequest)
                    await dataStore.updateDailyLogId(for: date, id: logResponse.data.documentId)
                    logger.debug("Initial daily diet log created for \(dateStr) with ID: \(logResponse.data.documentId)")
                }
            }
            
            let sortedMeals = schedule.sorted { DateFormatter.timeFormatter.date(from: $0.time)! < DateFormatter.timeFormatter.date(from: $1.time)! }
            await updateCurrentMeal(schedule: sortedMeals)
            
            let nutrition = try await HealthService().getMealNutrition(date: date)
            let caloriesLogged = sortedMeals.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories } } + nutrition.calories
            let protein = sortedMeals.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) } } + nutrition.protein
            let carbs = sortedMeals.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) } } + nutrition.carbs
            let fat = sortedMeals.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) } } + nutrition.fat
            let fiber = sortedMeals.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) } }
            
            let newMealsData = await dataStore.mealsData.copy(
                bmr: bmr,
                caloriesLogged: caloriesLogged,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                schedule: sortedMeals,
                currentMeal: nil,
                streak: await dataStore.mealsData.streak,
                questActive: totalProteinGoal > 0,
                questGoal: "Protein",
                questProgress: protein,
                questTarget: totalProteinGoal,
                selectedDate: date,
                mealType: await dataStore.mealsData.mealType,
                favoriteFood: await dataStore.mealsData.favoriteFood,
                customMealRequested: await dataStore.mealsData.customMealRequested,
                customMealMessage: await dataStore.mealsData.customMealMessage,
                hasDietPlan: activePlan != nil,
                recipes: await dataStore.mealsData.recipes,
                proteinGoal: totalProteinGoal,
                carbsGoal: totalCarbsGoal,
                targetKcal: targetKcal,
                fatGoal: totalFatGoal,
                fiberGoal: totalFiberGoal
            )
            
            await dataStore.updateMealsData(newMealsData)
            await MainActor.run {
                self.mealsDataState = newMealsData
            }
        } catch {
            logger.error("Error fetching meals data: \(error.localizedDescription)")
        }
    }
    
    private func calculateAge(from dateOfBirth: String?) -> Int {
        guard let dob = dateOfBirth, let date = ISO8601DateFormatter().date(from: dob) else { return 30 }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 30
    }
    
    private func calculateTDEE(bmr: Float, activityLevel: String?, age: Int, bmi: Double) -> Float {
        let multiplier: Float = switch activityLevel {
        case "Sedentary": 1.2
        case "Lightly Active": 1.375
        case "Moderately Active": 1.55
        case "Very Active": 1.725
        case "Extremely Active": 1.9
        default: 1.2
        }
        var tdee = bmr * multiplier
        if age > 50 { tdee *= 0.95 }
        if bmi > 30 { tdee *= 0.9 }
        return tdee
    }
    
    private func isoToDisplayTime(_ iso: String?) -> String {
        guard
            let iso,
            let date = ISO8601DateFormatter().date(from: iso)
        else { return "00:00" }
        return DateFormatter.timeFormatter.string(from: date)
    }

    
    private func calorieAdjustment(for strategy: String) -> Float {
        switch strategy {
        case "Lean-(0.25 kg/week)": return -250
        case "Aggressive-(0.5 kg/week)": return -500
        case "Gain-(0.25 kg/week)": return 250
        case "Gain-(0.5 kg/week)": return 500
        default: return 0
        }
    }
    
    func calculateStreak() async {
        do {
            guard let userId = auth.authState.userId,
                  let _  = auth.authState.jwt else {
                logger.error("Missing userId or token")
                let reset = await dataStore.mealsData.copy(streak: 0)
                await dataStore.updateMealsData(reset)
                await MainActor.run { self.mealsDataState = reset }
                return
            }

            var streakCount = 0
            var currentDate = Date()

            while true {
                let dateStr   = dateFormatter.string(from: currentDate)
                let dietLogs  = try await strapi.getDietLogs(userId: userId, dateString: dateStr,)
                if dietLogs.data.isEmpty { break }

                let hasConsumed = dietLogs.data.contains { log in
                    log.meals?.contains { meal in
                        meal.components.contains(where: \.consumed)
                    } ?? false
                }
                if !hasConsumed { break }

                streakCount += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            }

            let updated     = await dataStore.mealsData.copy(streak: streakCount)
            await dataStore.updateMealsData(updated)

            let count = streakCount           // ⬅︎ immutable constant
            await MainActor.run {
                self.mealsDataState = updated
                self.logger.debug("Calculated streak: \(count) days")
            }
        } catch {
            logger.error("Error calculating streak: \(error.localizedDescription)")
            let reset = await dataStore.mealsData.copy(streak: 0)
            await dataStore.updateMealsData(reset)
            await MainActor.run { self.mealsDataState = reset }
        }
    }

    func setDate(_ date: Date) async {
        let newMealsData = await dataStore.mealsData.copy(selectedDate: date)
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
        await fetchMealsData(date: date)
    }
    
    func setMealType(_ type: String) async {
        let newMealsData = await dataStore.mealsData.copy(mealType: type)
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
        await fetchAllDietComponents()
    }
    
    func applyFavouriteSelections(breakfast: [String], lunch: [String], dinner: [String], snack: [String]) {
        favoriteSelections[.breakfast] = breakfast
        favoriteSelections[.lunch] = lunch
        favoriteSelections[.dinner] = dinner
        favoriteSelections[.snack] = snack
    }
    
    func addFavourite(name: String, for type: MealType) async {
        await MainActor.run {
            self.favoriteSelections[type, default: []].append(name)
            if !self.favoriteFoodsState.contains(name) {
                self.favoriteFoodsState.append(name)
            }
        }
    }
    

    
    func generatePlan() async {
        do {
            guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
                logger.error("Missing userId or token")
                return
            }
            let date = await dataStore.mealsData.selectedDate
            let dateStr = dateFormatter.string(from: date)
            let healthVitals = try await strapi.getHealthVitals(userId: userId)
            let vitals = healthVitals.data.first
            let bmr = Float(vitals?.calorieGoal ?? 1800)
            let strategy = vitals?.weight_loss_strategy ?? "Maintain"
            let age = calculateAge(from: vitals?.date_of_birth)
            let bmi = vitals?.BMI ?? 25.0
            let tdee = calculateTDEE(bmr: bmr, activityLevel: vitals?.activity_level, age: age, bmi: bmi)
            let calorieAdjustment = calorieAdjustment(for: strategy)
            let targetCalories = tdee + calorieAdjustment
            let perMealCalories = targetCalories / Float(mealsPerDay)
            
            let dietPlanResponse = try await strapi.getDietPlan(userId: userId, date: date)
            let previousActive = dietPlanResponse.data.first(where: { $0.active })
            let todayPlan = dietPlanResponse.data.first { $0.active && $0.meals?.contains { $0.mealDate == dateStr } ?? false }
            let activePlan = todayPlan

            
            var meals: [MealSlot] = []
            var mealIds: [String] = []
            var totalProteinGoal: Float = 0
            var totalCarbsGoal: Float = 0
            var totalFatGoal: Float = 0
            var totalFiberGoal: Float = 0
            
            let mealSlots: [(type: String, fav: String, time: String)] = {
                switch mealsPerDay {
                case 3:
                    return [
                        ("Breakfast", favoriteSelections[.breakfast]?.first ?? "Oatmeal", "08:00:00.000"),
                        ("Lunch", favoriteSelections[.lunch]?.first ?? "Chicken Salad", "13:00:00.000"),
                        ("Dinner", favoriteSelections[.dinner]?.first ?? "Grilled Fish", "19:00:00.000")
                    ]
                case 4:
                    return [
                        ("Breakfast", favoriteSelections[.breakfast]?.first ?? "Oatmeal", "08:00:00.000"),
                        ("Lunch", favoriteSelections[.lunch]?.first ?? "Chicken Salad", "13:00:00.000"),
                        ("Snack", favoriteSelections[.snack]?.first ?? "Fruit", "16:00:00.000"),
                        ("Dinner", favoriteSelections[.dinner]?.first ?? "Grilled Fish", "19:00:00.000")
                    ]
                default:
                    var slots = [
                        ("Breakfast", favoriteSelections[.breakfast]?.first ?? "Oatmeal", "08:00:00.000"),
                        ("Lunch", favoriteSelections[.lunch]?.first ?? "Chicken Salad", "13:00:00.000"),
                        ("Dinner", favoriteSelections[.dinner]?.first ?? "Grilled Fish", "19:00:00.000")
                    ]
                    let extras = favoriteSelections[.snack]?.prefix(mealsPerDay - 3) ?? []
                    slots.append(contentsOf: extras.enumerated().map { (index, fav) in
                        ("Meal \(index + 4)", fav, "\(10 + index * 2):00:00.000")
                    })
                    return slots
                }
            }()
            
            for (type, fav, time) in mealSlots {
                // Get the meal type enum
                let mealType: MealType
                switch type {
                case "Breakfast": mealType = .breakfast
                case "Lunch": mealType = .lunch
                case "Dinner": mealType = .dinner
                case "Snack": mealType = .snack
                default: mealType = .breakfast
                }
                
                // Get user's selected items for this meal type
                let selectedItems = favoriteSelections[mealType] ?? []
                
                // Use first item as primary, second as filler (if available)
                let primaryItem = selectedItems.first ?? fav
                let secondaryItem = selectedItems.count > 1 ? selectedItems[1] : nil
                
                let primaryComponent = searchComponents.first { $0.name == primaryItem }
                let primaryCalories = Float(primaryComponent?.calories ?? 200)
                
                // Calculate remaining calories for secondary item
                let remainingCalories = perMealCalories - primaryCalories
                
                // Use user's second selection if available, otherwise pick a random filler
                let secondaryComponent: DietComponentEntry?
                let secondaryCalories: Float
                let scale: Float
                
                if let secondaryItem = secondaryItem {
                    // User selected a second item
                    secondaryComponent = searchComponents.first { $0.name == secondaryItem }
                    secondaryCalories = Float(secondaryComponent?.calories ?? 0)
                    scale = secondaryCalories > 0 ? remainingCalories / secondaryCalories : 1
                } else {
                    // No second item selected, use random filler
                    secondaryComponent = searchComponents.filter { $0.name != primaryItem }.randomElement()
                    secondaryCalories = Float(secondaryComponent?.calories ?? 0)
                    scale = secondaryCalories > 0 ? remainingCalories / secondaryCalories : 1
                }
                
                let mealProtein = parseMacro(primaryComponent?.protein) + parseMacro(secondaryComponent?.protein) * scale
                let mealCarbs = parseMacro(primaryComponent?.carbohydrate) + parseMacro(secondaryComponent?.carbohydrate) * scale
                let mealFat = parseMacro(primaryComponent?.totalFat) + parseMacro(secondaryComponent?.totalFat) * scale
                let mealFiber = parseMacro(primaryComponent?.fiber) + parseMacro(secondaryComponent?.fiber) * scale
                
                totalProteinGoal += mealProtein
                totalCarbsGoal += mealCarbs
                totalFatGoal += mealFat
                totalFiberGoal += mealFiber
                
                let mealRequest = MealRequest(
                    name: "\(type) Meal",
                    mealTime: time,
                    basePortion: Int(primaryCalories + (secondaryCalories * scale)),
                    basePortionUnit: "Serving",
                    totalCalories: Int(perMealCalories),
                    mealDate: dateStr,
                    dietComponents: [primaryComponent?.documentId, secondaryComponent?.documentId].compactMap { $0 }
                )
                
                let mealResponse = if let activePlan, let existingMeal = activePlan.meals?.first(where: { $0.name == "\(type) Meal" && $0.mealDate == dateStr }) {
                    try await strapi.updateMeal(documentId: existingMeal.documentId, body: mealRequest)
                } else {
                    try await strapi.postMeal(body: mealRequest)
                }
                
                let mealId = mealResponse.data.documentId
                mealIds.append(mealId)
                let displayTime = DateFormatter.timeFormatter.string(from: ISO8601DateFormatter().date(from: time) ?? Date())
                let missed = (DateFormatter.timeFormatter.date(from: displayTime)?.isBeforeNow ?? false)
                
                meals.append(MealSlot(
                    id: mealId,
                    type: type,
                    time: displayTime,
                    items: [
                        MealItem(
                            id: primaryComponent?.documentId ?? "unknown",
                            name: primaryComponent?.name ?? "Unknown",
                            servingSize: primaryCalories,
                            calories: primaryCalories,
                            unit: primaryComponent?.unit ?? "Serving",
                            isConsumed: false,
                            imageUrl: primaryComponent?.recipeUrl
                        ),
                        MealItem(
                            id: secondaryComponent?.documentId ?? "extra",
                            name: secondaryComponent?.name ?? "Extra",
                            servingSize: secondaryCalories * scale,
                            calories: secondaryCalories * scale,
                            unit: secondaryComponent?.unit ?? "Serving",
                            isConsumed: false,
                            imageUrl: secondaryComponent?.recipeUrl
                        )
                    ],
                    calories: 0,
                    protein: mealProtein,
                    carbs: mealCarbs,
                    fat: mealFat,
                    fiber: mealFiber,
                    date: date,
                    isMissed: missed,
                    targetCalories: perMealCalories
                ))
            }
            
            let sortedMeals = meals.sorted { DateFormatter.timeFormatter.date(from: $0.time)! < DateFormatter.timeFormatter.date(from: $1.time)! }
            
            let dietPlanRequest = DietPlanRequest(
                planId: activePlan?.planId ?? "diet_plan_\(Date().timeIntervalSince1970)",
                totalCalories: Int(targetCalories),
                dietPreference: await dataStore.mealsData.mealType,
                active: true,
                pointsEarned: activePlan?.pointsEarned ?? 0,
                dietGoal: strategy,
                meals: mealIds,
                usersPermissionsUser: UserId(id: userId)
            )
            
            if let activePlan {
                let _ = try await strapi.updateDietPlan(documentId: activePlan.documentId, body: dietPlanRequest)
            } else {
                let _ = try await strapi.postDietPlan(body: dietPlanRequest)
            }
            
            if let prev = previousActive,
               prev.documentId != todayPlan?.documentId {

                // Build a request payload (all fields your endpoint requires)
                let deactivateReq = DietPlanRequest(
                    planId:           prev.planId,
                    totalCalories:    prev.totalCalories,
                    dietPreference:   prev.dietPreference,
                    active:           false,
                    pointsEarned:     prev.pointsEarned,
                    dietGoal:         prev.dietGoal,
                    meals:            prev.meals?.map { $0.documentId } ?? [],
                    usersPermissionsUser: UserId(id: userId)
                )

                _ = try await strapi.updateDietPlan(
                        documentId: prev.documentId,
                        body:       deactivateReq
                )
            }

            if activePlan == nil {
                for mealId in mealIds {
                    if let meal = meals.first(where: { $0.id == mealId }) {
                        let mealRequest = MealRequest(
                            name: "\(meal.type) Meal",
                            mealTime: meal.time + ":00.000",
                            basePortion: Int(meal.items.reduce(0) { $0 + $1.servingSize }),
                            basePortionUnit: "Serving",
                            totalCalories: Int(meal.items.reduce(0) { $0 + $1.calories }),
                            mealDate: dateStr,
                            dietComponents: meal.items.map { $0.id }
                        )
                        let _ = try await strapi.updateMeal(documentId: mealId, body: mealRequest)
                    }
                }
            }
            
            let dietLogRequest = DietLogRequest(
                date: dateStr,
                usersPermissionsUser: UserId(id: userId),
                meals: sortedMeals.map { meal in
                    MealLogEntry(
                        mealId: meal.id,
                        components: meal.items.map { ComponentLogEntry(componentId: $0.id, consumed: $0.isConsumed) }
                    )
                }
            )
            let logResponse = try await strapi.postDietLog(body: dietLogRequest)
            await dataStore.updateDailyLogId(for: date, id: logResponse.data.documentId)
            
            let newMealsData = await dataStore.mealsData.copy(
                bmr: bmr,
                caloriesLogged: await dataStore.mealsData.caloriesLogged,
                protein: await dataStore.mealsData.protein,
                carbs: await dataStore.mealsData.carbs,
                fat: await dataStore.mealsData.fat,
                fiber: await dataStore.mealsData.fiber,
                schedule: sortedMeals,
                currentMeal: nil,
                streak: await dataStore.mealsData.streak,
                questActive: totalProteinGoal > 0,
                questGoal: "Protein",
                questProgress: await dataStore.mealsData.protein,
                questTarget: totalProteinGoal,
                selectedDate: date,
                mealType: await dataStore.mealsData.mealType,
                favoriteFood: await dataStore.mealsData.favoriteFood,
                customMealRequested: await dataStore.mealsData.customMealRequested,
                customMealMessage: await dataStore.mealsData.customMealMessage,
                hasDietPlan: true,
                recipes: await dataStore.mealsData.recipes,
                proteinGoal: totalProteinGoal,
                carbsGoal: totalCarbsGoal,
                targetKcal: targetCalories,
                fatGoal: totalFatGoal,
                fiberGoal: totalFiberGoal
            )
            
            await dataStore.updateMealsData(newMealsData)
            await MainActor.run {
                self.mealsDataState = newMealsData
                self.logger.debug("Initial daily diet log created for \(dateStr)")
            }
            await updateCurrentMeal(schedule: sortedMeals)
            await fetchRecipes()
            
            // Show share option after plan creation
            await showShareOption()
        } catch {
            logger.error("Error creating diet plan: \(error.localizedDescription)")
        }
    }
    
    func updateCurrentMeal(schedule: [MealSlot]) async {
        let currentTime = DateFormatter.timeFormatter.date(from: DateFormatter.timeFormatter.string(from: Date()))!
        let firstUnconsumed = schedule.first { $0.items.contains { !$0.isConsumed } }
        let currentMeal = firstUnconsumed ?? schedule.first
        let updatedSchedule = schedule.map { meal in
            let mealTime = DateFormatter.timeFormatter.date(from: meal.time)!
            let missed = mealTime < currentTime && meal.items.contains { !$0.isConsumed }
            return meal.copy(isMissed: missed)
        }
        let newMealsData = await dataStore.mealsData.copy(schedule: updatedSchedule, currentMeal: currentMeal)
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
    }
    
    func toggleConsumption(mealIndex: Int, itemIndex: Int) async {
        guard mealIndex >= 0, mealIndex < mealsDataState.schedule.count else {
            logger.error("Invalid mealIndex: \(mealIndex), schedule size: \(self.mealsDataState.schedule.count)")
            return
        }
        let meal = mealsDataState.schedule[mealIndex]
        guard itemIndex >= 0, itemIndex < meal.items.count else {
            logger.error("Invalid itemIndex: \(itemIndex), items size: \(meal.items.count)")
            return
        }
        
        var schedule = mealsDataState.schedule
        var items = meal.items
        let item = items[itemIndex]
        items[itemIndex] = item.copy(isConsumed: !item.isConsumed)
        let missed = (DateFormatter.timeFormatter.date(from: meal.time)?.isBeforeNow ?? false) && items.contains { !$0.isConsumed }
        schedule[mealIndex] = meal.copy(
            items: items,
            calories: items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories },
            isMissed: missed
        )
        
        let caloriesLogged = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories } }
        let protein = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) } }
        let carbs = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) } }
        let fat = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) } }
        let fiber = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) } }
        
        let newMealsData = await dataStore.mealsData.copy(
            caloriesLogged: caloriesLogged,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            schedule: schedule,
            questProgress: protein
        )
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
        await updateDailyLog()
        await updateCurrentMeal(schedule: schedule)
    }
    
    func replaceMealComponent(mealIndex: Int, itemIndex: Int, newComponentId: String) async {
        guard mealIndex >= 0, mealIndex < mealsDataState.schedule.count else {
            logger.error("Invalid mealIndex: \(mealIndex), schedule size: \(self.mealsDataState.schedule.count)")
            return
        }
        let meal = mealsDataState.schedule[mealIndex]
        guard itemIndex >= 0, itemIndex < meal.items.count else {
            logger.error("Invalid itemIndex: \(itemIndex), items size: \(meal.items.count)")
            return
        }
        guard let newComponent = componentsCache[newComponentId] else {
            logger.error("Component not found for ID: \(newComponentId)")
            return
        }
        guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
            logger.error("Missing userId or token")
            return
        }
        
        var schedule = mealsDataState.schedule
        var items = meal.items
        let oldItem = items[itemIndex]
        let baseCalories = Float(newComponent.calories ?? 0)
        let scale = baseCalories > 0 ? meal.targetCalories / baseCalories : 1
        items[itemIndex] = MealItem(
            id: newComponent.documentId ?? UUID().uuidString,
            name: newComponent.name,
            servingSize: Float(newComponent.portionSize ?? 100) * scale,
            calories: meal.targetCalories,
            unit: newComponent.unit ?? "Serving",
            isConsumed: oldItem.isConsumed,
            imageUrl: newComponent.recipeUrl
        )
        schedule[mealIndex] = meal.copy(
            items: items,
            calories: items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories },
            protein: items.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) * scale },
            carbs: items.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) * scale },
            fat: items.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) * scale },
            fiber: items.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) * scale }
        )
        
        let caloriesLogged = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories } }
        let protein = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) } }
        let carbs = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) } }
        let fat = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) } }
        let fiber = schedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) } }
        
        let newMealsData = await dataStore.mealsData.copy(
            caloriesLogged: caloriesLogged,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            schedule: schedule,
            questProgress: protein
        )
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
        
        do {
            let feedbackRequest = FeedbackRequest(
                userId: userId,
                mealId: meal.id,
                oldComponentId: oldItem.id,
                newComponentId: newComponentId,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            let _ = try await strapi.postFeedback(request: feedbackRequest)
            
            let dietPlanResponse = try await strapi.getDietPlan(userId: userId, date: mealsDataState.selectedDate)
            if let activePlan = dietPlanResponse.data.first(where: { $0.active }) {
                if let mealToUpdate = activePlan.meals?.first(where: { $0.documentId == meal.id }) {
                    let updatedComponents: [String] = mealToUpdate.dietComponents?.enumerated().compactMap { (idx, comp) in
                        idx == itemIndex ? newComponent.documentId : comp.documentId
                    } ?? []
                    let mealRequest = MealRequest(
                        name: mealToUpdate.name,
                        mealTime: mealToUpdate.mealTime,
                        basePortion: mealToUpdate.basePortion,
                        basePortionUnit: "Serving",
                        totalCalories: mealToUpdate.totalCalories,
                        mealDate: mealToUpdate.mealDate,
                        dietComponents: updatedComponents
                    )
                    let _ = try await strapi.updateMeal(documentId: mealToUpdate.documentId, body: mealRequest)
                    logger.debug("Meal updated successfully: \(mealToUpdate.documentId)")
                } else {
                    logger.error("Meal \(meal.id) not found in diet plan")
                }
            } else {
                logger.error("No active diet plan found")
            }
        } catch {
            logger.error("Error updating meal or posting feedback: \(error.localizedDescription)")
        }
        
        await updateDailyLog()
        await updateCurrentMeal(schedule: schedule)
    }
    
    private func updateDailyLog() async {
        do {
            guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
                logger.error("Missing userId or token")
                return
            }
            let date = await dataStore.mealsData.selectedDate
            let dateStr = dateFormatter.string(from: date)
            let schedule = await dataStore.mealsData.schedule
            
            let dietLogUpdateRequest = DietLogUpdateRequest(
                date: dateStr,
                meals: schedule.map { meal in
                    MealLogEntry(
                        mealId: meal.id,
                        components: meal.items.map { ComponentLogEntry(componentId: $0.id, consumed: $0.isConsumed) }
                    )
                }
            )
            
            if let logId = await dataStore.getDailyLogId(for: date) {
                _ = try await strapi.putDietLog(logId: logId, request: dietLogUpdateRequest)
                logger.debug("Daily diet log updated for \(dateStr) with PUT (logId: \(logId))")
            } else {
                let dietLogRequest = DietLogRequest(
                    date: dateStr,
                    usersPermissionsUser: UserId(id: userId),
                    meals: schedule.map { meal in
                        MealLogEntry(
                            mealId: meal.id,
                            components: meal.items.map { ComponentLogEntry(componentId: $0.id, consumed: $0.isConsumed) }
                        )
                    }
                )
                let postResponse = try await strapi.postDietLog(body: dietLogRequest)
                await dataStore.updateDailyLogId(for: date, id: postResponse.data.documentId)
                logger.debug("Initial daily diet log created for \(dateStr) with ID: \(postResponse.data.documentId)")
            }
        } catch {
            logger.error("Error updating diet log: \(error.localizedDescription)")
        }
    }
    
    func requestCustomMeal(food: String) async {
        do {
            guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
                logger.error("Missing userId or token")
                return
            }
            let _ = try await strapi.postCustomMealRequest(request: CustomMealRequest(userId: userId, food: food))
            var currentSchedule = await dataStore.mealsData.schedule
            let newMeal = MealSlot(
                id: "custom_\(Date().timeIntervalSince1970)",
                type: "Custom",
                time: DateFormatter.timeFormatter.string(from: Date()),
                items: [MealItem(id: "custom_\(Date().timeIntervalSince1970)", name: food, servingSize: 500, calories: 500, unit: "Serving", isConsumed: false, imageUrl: nil)],
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0,
                date: await dataStore.mealsData.selectedDate,
                isMissed: false,
                targetCalories: 500
            )
            currentSchedule.append(newMeal)
            let newMealsData = await dataStore.mealsData.copy(
                schedule: currentSchedule,
                customMealRequested: true,
                customMealMessage: "Wait while we cook a great plan for you!",
            )
            await dataStore.updateMealsData(newMealsData)
            await MainActor.run {
                self.mealsDataState = newMealsData
            }
            await updateDailyLog()
            await updateCurrentMeal(schedule: currentSchedule)
        } catch {
            logger.error("Error requesting custom meal: \(error.localizedDescription)")
        }
    }
    
    func sendToCookingBuddy(slot: MealSlot) async {
        do {
            guard let userId = auth.authState.userId, let _ = auth.authState.jwt else {
                logger.error("Missing userId or token")
                return
            }
            let _ = try await strapi.postMealGoal(request: MealGoalRequest(
                userId: userId,
                meal: slot.items.map { $0.name }.joined(separator: ", "),
                calories: slot.calories,
                time: slot.time
            ))
            logger.debug("Sent to Cooking Buddy: \(slot.items.map { $0.name }.joined(separator: ", "))")
        } catch {
            logger.error("Error sending to Cooking Buddy: \(error.localizedDescription)")
        }
    }
    
    func fetchRecipes() async {
        do {
            // ── 1. Auth guard ───────────────────────────────────────────
            guard let userId = auth.authState.userId,
                  auth.authState.jwt != nil else {
                logger.error("Missing userId or token")
                return
            }

            // ── 2. Get the active diet plan (date arg ignored by repo) ─
            let today        = await dataStore.mealsData.selectedDate
            let planResponse = try await strapi.getDietPlan(userId: userId, date: today)

            guard let activePlan = planResponse.data.first(where: { $0.active }) else {
                logger.warning("No active diet plan returned")
                let cleared = await dataStore.mealsData.copy(recipes: [])
                await dataStore.updateMealsData(cleared)
                await MainActor.run { self.mealsDataState = cleared }
                return
            }

            // ── 3. Flatten every DietComponentEntry in the plan ────────
            let flatComponents: [DietComponentEntry] =
                activePlan.meals?.flatMap { $0.dietComponents ?? [] } ?? []

            // ── 4. De-duplicate by documentId using a Set  ─────────────
            var seen = Set<String>()
            var uniqueComponents: [DietComponentEntry] = []

            for comp in flatComponents {
                let id = comp.documentId ?? UUID().uuidString
                if seen.insert(id).inserted {
                    uniqueComponents.append(comp)
                }
            }

            // ── 5. Build DietComponentCard array  ──────────────────────
            var cards: [DietComponentCard] = []

            for comp in uniqueComponents {
                let id   = comp.documentId ?? UUID().uuidString
                let kcal = comp.calories ?? 0
                let prot = comp.protein      ?? "0g"
                let carb = comp.carbohydrate ?? "0g"
                let fat  = comp.totalFat     ?? "0g"
                let fib  = comp.fiber        ?? "0g"

                logger.debug("Component \(id, privacy: .public) • \(comp.name, privacy: .public) • \(kcal) kcal")

                cards.append(
                    DietComponentCard(
                        id:       id,
                        name:     comp.name,
                        calories: "\(kcal)",
                        protein:  prot,
                        carbs:    carb,
                        fat:      fat,
                        fiber:    fib
                    )
                )
            }

            logger.debug("Fetched \(cards.count) recipe components")

            // ── 6. Commit to state  ────────────────────────────────────
            let updated = await dataStore.mealsData.copy(recipes: cards)
            await dataStore.updateMealsData(updated)
            await MainActor.run { self.mealsDataState = updated }

        } catch {
            logger.error("Error fetching recipes: \(error.localizedDescription)")
            let cleared = await dataStore.mealsData.copy(recipes: [])
            await dataStore.updateMealsData(cleared)
            await MainActor.run { self.mealsDataState = cleared }
        }
    }

    func logRecipe(recipe: String) async {
        guard auth.authState.userId != nil,           // keep the presence check
              auth.authState.jwt  != nil else {
            logger.error("Missing userId or token")
            return
        }


        let recipeName = recipe.components(separatedBy: " - ").first ?? recipe
        guard let component = searchComponents.first(where: { $0.name == recipeName }) else { return }

        var schedule = await dataStore.mealsData.schedule
        let newMeal = MealSlot(
            id: "recipe_\(Date().timeIntervalSince1970)",
            type: "Recipe",
            time: DateFormatter.timeFormatter.string(from: Date()),
            items: [
                                    MealItem(
                        id: component.documentId ?? UUID().uuidString,
                        name: component.name,
                        servingSize: Float(component.calories ?? 0),
                        calories: Float(component.calories ?? 0),
                        unit: component.unit ?? "Serving",
                        isConsumed: true,
                        imageUrl: component.recipeUrl
                    )
            ],
            calories: Float(component.calories ?? 0),
            protein: parseMacro(component.protein),
            carbs:  parseMacro(component.carbohydrate),
            fat:    parseMacro(component.totalFat),
            fiber:  parseMacro(component.fiber),
            date:   await dataStore.mealsData.selectedDate,
            isMissed: false,
            targetCalories: Float(component.calories ?? 0)
        )
        schedule.append(newMeal)

        let caloriesLogged = schedule.reduce(0) { $0 + $1.items.filter(\.isConsumed).map(\.calories).reduce(0, +) }
        let proteinTotal   = schedule.reduce(0) { $0 + $1.items.filter(\.isConsumed).reduce(0) { $0 + parseMacro(componentsCache[$1.id]?.protein) } }
        let carbsTotal     = schedule.reduce(0) { $0 + $1.items.filter(\.isConsumed).reduce(0) { $0 + parseMacro(componentsCache[$1.id]?.carbohydrate) } }
        let fatTotal       = schedule.reduce(0) { $0 + $1.items.filter(\.isConsumed).reduce(0) { $0 + parseMacro(componentsCache[$1.id]?.totalFat) } }
        let fiberTotal     = schedule.reduce(0) { $0 + $1.items.filter(\.isConsumed).reduce(0) { $0 + parseMacro(componentsCache[$1.id]?.fiber) } }

        let newMealsData = await dataStore.mealsData.copy(
            caloriesLogged: caloriesLogged,
            protein:  proteinTotal,
            carbs:    carbsTotal,
            fat:      fatTotal,
            fiber:    fiberTotal,
            schedule: schedule,
            questProgress: proteinTotal
        )
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run { self.mealsDataState = newMealsData }

        await updateDailyLog()
        await updateCurrentMeal(schedule: schedule)

        logger.debug("Logged recipe: \(recipe, privacy: .public)")
    }

    func logPhotoMeal(mealName: String, calories: Float, protein: Float, carbs: Float, fat: Float, fiber: Float) async {
        var currentSchedule = await dataStore.mealsData.schedule
        let newMeal = MealSlot(
            id: "photo_\(Date().timeIntervalSince1970)",
            type: "Photo Meal",
            time: DateFormatter.timeFormatter.string(from: Date()),
            items: [
                MealItem(
                    id: "photo_\(Date().timeIntervalSince1970)",
                    name: mealName,
                    servingSize: calories,
                    calories: calories,
                    unit: "Serving",
                    isConsumed: true,
                    imageUrl: nil
                )
            ],
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            date: await dataStore.mealsData.selectedDate,
            isMissed: false,
            targetCalories: calories
        )
        currentSchedule.append(newMeal)
        let caloriesLogged = currentSchedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + $1.calories } }
        let proteinTotal = currentSchedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.protein) } } + protein
        let carbsTotal = currentSchedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.carbohydrate) } } + carbs
        let fatTotal = currentSchedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.totalFat) } } + fat
        let fiberTotal = currentSchedule.reduce(0) { $0 + $1.items.filter { $0.isConsumed }.reduce(0) { $0 + parseMacro(self.componentsCache[$1.id]?.fiber) } } + fiber
        
        let newMealsData = await dataStore.mealsData.copy(
            caloriesLogged: caloriesLogged,
            protein: proteinTotal,
            carbs: carbsTotal,
            fat: fatTotal,
            fiber: fiberTotal,
            schedule: currentSchedule,
            questProgress: proteinTotal
        )
        await dataStore.updateMealsData(newMealsData)
        await MainActor.run {
            self.mealsDataState = newMealsData
        }
        await updateDailyLog()
        await updateCurrentMeal(schedule: currentSchedule)
        logger.debug("Logged photo meal: \(mealName), \(calories) Kcal")
    }
    
    func hasDietPlanForDate(date: Date) -> Bool {
        return mealsDataState.hasDietPlan && mealsDataState.schedule.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    // MARK: - Share Functionality
    @Published var showShareDialog = false
    @Published var shareText = ""
    
    private func showShareOption() async {
        await MainActor.run {
            // Create share text with meal plan details
            let mealPlanText = createMealPlanShareText()
            self.shareText = mealPlanText
            self.showShareDialog = true
        }
    }
    
    private func createMealPlanShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var shareText = "🍽️ My FitGlide Meal Plan for \(dateFormatter.string(from: mealsDataState.selectedDate))\n\n"
        
        for meal in mealsDataState.schedule {
            shareText += "\(meal.type):\n"
            for item in meal.items {
                shareText += "• \(item.name) (\(Int(item.calories)) kcal)\n"
            }
            shareText += "\n"
        }
        
        shareText += "Total Calories: \(Int(mealsDataState.targetKcal)) kcal\n"
        shareText += "Protein: \(Int(mealsDataState.proteinGoal))g | Carbs: \(Int(mealsDataState.carbsGoal))g | Fat: \(Int(mealsDataState.fatGoal))g\n\n"
        shareText += "Join me on FitGlide for personalized meal plans! 🚀"
        
        return shareText
    }
    
    func shareMealPlan() {
        // This will be called from the UI to trigger the share sheet
        showShareDialog = true
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter
    }()
}

extension Date {
    var isBeforeNow: Bool {
        return self < Date()
    }
}



extension Sequence {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

extension Sequence {
    func uniqued<T: Hashable>(by keySelector: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return self.filter { seen.insert(keySelector($0)).inserted }
    }
}
