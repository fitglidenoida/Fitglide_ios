//
//  MealModels.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/06/25.
//

import Foundation
import SwiftUI

struct MealsData {
    let bmr: Float
    let caloriesLogged: Float
    let protein: Float
    let carbs: Float
    let fat: Float
    let fiber: Float
    let schedule: [MealSlot]
    let currentMeal: MealSlot?
    let streak: Int
    let questActive: Bool
    let questGoal: String
    let questProgress: Float
    let questTarget: Float
    let selectedDate: Date
    let mealType: String
    let favoriteFood: String
    let customMealRequested: Bool
    let customMealMessage: String
    let hasDietPlan: Bool
    let recipes: [DietComponentCard]
    let proteinGoal: Float
    let carbsGoal: Float
    let targetKcal: Float
    let fatGoal: Float
    let fiberGoal: Float
}

struct MealSlot: Equatable, Identifiable, Codable {
    let id: String
    let type: String
    let time: String
    var items: [MealItem]
    var calories: Float
    var protein: Float
    var carbs: Float
    var fat: Float
    var fiber: Float
    let date: Date
    let isMissed: Bool
    let targetCalories: Float
}

struct MealItem: Equatable, Identifiable, Codable {
    let id: String
    let name: String
    let servingSize: Float
    let calories: Float
    let unit: String                  // ← NEW
    var isConsumed: Bool
}

struct DietComponentCard: Identifiable {
    let id: String
    let name: String
    let calories: String
    let protein: String
    let carbs: String
    let fat: String
    let fiber: String
}

extension MealsData {
    func copy(
        bmr: Float? = nil,
        caloriesLogged: Float? = nil,
        protein: Float? = nil,
        carbs: Float? = nil,
        fat: Float? = nil,
        fiber: Float? = nil,
        schedule: [MealSlot]? = nil,
        currentMeal: MealSlot? = nil,
        streak: Int? = nil,
        questActive: Bool? = nil,
        questGoal: String? = nil,
        questProgress: Float? = nil,
        questTarget: Float? = nil,
        selectedDate: Date? = nil,
        mealType: String? = nil,
        favoriteFood: String? = nil,
        customMealRequested: Bool? = nil,
        customMealMessage: String? = nil,
        hasDietPlan: Bool? = nil,
        recipes: [DietComponentCard]? = nil,
        proteinGoal: Float? = nil,
        carbsGoal: Float? = nil,
        /*** NEW ***/  targetKcal: Float? = nil,
        fatGoal: Float? = nil,
        fiberGoal: Float? = nil
    ) -> MealsData {
        MealsData(
            bmr:           bmr           ?? self.bmr,
            caloriesLogged:caloriesLogged ?? self.caloriesLogged,
            protein:       protein       ?? self.protein,
            carbs:         carbs         ?? self.carbs,
            fat:           fat           ?? self.fat,
            fiber:         fiber         ?? self.fiber,
            schedule:      schedule      ?? self.schedule,
            currentMeal:   currentMeal   ?? self.currentMeal,
            streak:        streak        ?? self.streak,
            questActive:   questActive   ?? self.questActive,
            questGoal:     questGoal     ?? self.questGoal,
            questProgress: questProgress ?? self.questProgress,
            questTarget:   questTarget   ?? self.questTarget,
            selectedDate:  selectedDate  ?? self.selectedDate,
            mealType:      mealType      ?? self.mealType,
            favoriteFood:  favoriteFood  ?? self.favoriteFood,
            customMealRequested: customMealRequested ?? self.customMealRequested,
            customMealMessage:  customMealMessage  ?? self.customMealMessage,
            hasDietPlan:   hasDietPlan   ?? self.hasDietPlan,
            recipes:       recipes       ?? self.recipes,
            proteinGoal:   proteinGoal   ?? self.proteinGoal,
            carbsGoal:     carbsGoal     ?? self.carbsGoal,
            targetKcal:    targetKcal    ?? self.targetKcal,
            fatGoal:       fatGoal       ?? self.fatGoal,
            fiberGoal:     fiberGoal     ?? self.fiberGoal
        )
    }
}

extension MealSlot {
    func copy(
        id: String? = nil,
        type: String? = nil,
        time: String? = nil,
        items: [MealItem]? = nil,
        calories: Float? = nil,
        protein: Float? = nil,
        carbs: Float? = nil,
        fat: Float? = nil,
        fiber: Float? = nil,
        date: Date? = nil,
        isMissed: Bool? = nil,
        targetCalories: Float? = nil
    ) -> MealSlot {
        MealSlot(
            id: id ?? self.id,
            type: type ?? self.type,
            time: time ?? self.time,
            items: items ?? self.items,
            calories: calories ?? self.calories,
            protein: protein ?? self.protein,
            carbs: carbs ?? self.carbs,
            fat: fat ?? self.fat,
            fiber: fiber ?? self.fiber,
            date: date ?? self.date,
            isMissed: isMissed ?? self.isMissed,
            targetCalories: targetCalories ?? self.targetCalories
        )
    }
}

extension MealItem {
    func copy(
        id: String? = nil,
        name: String? = nil,
        servingSize: Float? = nil,
        calories: Float? = nil,
        isConsumed: Bool? = nil
    ) -> MealItem {
        MealItem(
            id: id ?? self.id,
            name: name ?? self.name,
            servingSize: servingSize ?? self.servingSize,
            calories: calories ?? self.calories,
            unit: unit,
            isConsumed: isConsumed ?? self.isConsumed
        )
    }
}

extension HealthService {
    struct MealNutritionData {
        let calories: Float
        let protein: Float
        let carbs: Float
        let fat: Float
    }

    func getMealNutrition(date: Date) async throws -> MealNutritionData {
        // Placeholder: Implement HealthKit nutrition data fetching
        return MealNutritionData(calories: 0, protein: 0, carbs: 0, fat: 0)
    }
}
