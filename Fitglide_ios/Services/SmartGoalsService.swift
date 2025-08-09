import Foundation
import HealthKit
import Combine
import os.log
import SwiftUI // Added for Color

@MainActor
class SmartGoalsService: ObservableObject {
    @Published var currentGoal: SmartGoal?
    @Published var predictions: [GoalPrediction] = []
    @Published var recommendations: [GoalRecommendation] = []
    @Published var milestones: [GoalMilestone] = []
    @Published var achievements: [GoalAchievement] = []
    @Published var progressInsights: [ProgressInsight] = []
    @Published var dailyActions: [DailyAction] = []
    @Published var isLoading: Bool = false
    
    private let healthService: HealthService
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "SmartGoals")
    
    // Daily tracking properties
    private var lastActionDate: Date?
    private var refreshTimer: Timer?
    
    init(healthService: HealthService, strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.healthService = healthService
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        
        // Start automatic refresh timer
        startAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Auto Refresh System
    
    private func startAutoRefresh() {
        // Refresh every 5 minutes to keep data current
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndRefreshDailyActions()
            }
        }
    }
    
    private func checkAndRefreshDailyActions() async {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if we need to reset actions for a new day
        if let lastDate = lastActionDate {
            let lastActionDay = Calendar.current.startOfDay(for: lastDate)
            if today != lastActionDay {
                logger.info("New day detected, resetting daily actions")
                await resetDailyActionsForNewDay()
            }
        } else {
            // First time running, set up actions for today
            logger.info("First time setup, creating daily actions")
            await resetDailyActionsForNewDay()
        }
        
        // Update progress with current data
        await updateActionProgress()
    }
    
    private func resetDailyActionsForNewDay() async {
        guard let currentGoal = self.currentGoal else {
            logger.warning("No current goal available for daily actions reset")
            return
        }
        
        // Get actual user data for more accurate targets
        let tdee = await getActualTDEE()
        let weight = await getActualWeight()
        
        // Generate fresh daily actions for today
        let actions = await generateDailyActions(for: currentGoal, tdee: tdee, weight: weight)
        
        await MainActor.run {
            self.dailyActions = actions
            self.lastActionDate = Date()
        }
        
        logger.info("Reset daily actions for new day: \(actions.count) actions")
    }
    
    // MARK: - Smart Goal Analysis
    
    func analyzeUserProfileAndSuggestGoals() async {
        logger.debug("Starting smart goals analysis...")
        do {
            guard let userId = authRepository.authState.userId else {
                logger.error("No user ID available for smart goals analysis")
                return
            }
            
            logger.debug("Fetching health vitals for user: \(userId)")
            // Fetch user's health vitals
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            let vitals = vitalsResponse.data.first
            logger.debug("Fetched vitals: \(vitals?.life_goal_type ?? "nil")")
            
            // Analyze current health metrics
            logger.debug("Analyzing health metrics...")
            let analysis = await analyzeCurrentHealthMetrics(vitals: vitals)
            
            // Generate personalized goal suggestions
            logger.debug("Generating goal suggestions...")
            let suggestions = generateGoalSuggestions(analysis: analysis)
            logger.debug("Generated \(suggestions.count) suggestions")
            
            // Create smart goal recommendations
            logger.debug("Creating smart goal recommendations...")
            await createSmartGoalRecommendations(suggestions: suggestions, analysis: analysis)
            
            // Generate daily actions for current goal if available
            if let currentGoal = self.currentGoal {
                logger.debug("Generating daily actions for current goal: \(currentGoal.type)")
                let actions = await generateDailyActions(for: currentGoal)
                await MainActor.run {
                    self.dailyActions = actions
                }
                logger.debug("Generated \(actions.count) daily actions")
            }
            
            logger.debug("Smart goals analysis completed with \(suggestions.count) suggestions")
            
        } catch {
            logger.error("Failed to analyze user profile: \(error.localizedDescription)")
        }
    }
    
    private func analyzeCurrentHealthMetrics(vitals: HealthVitalsEntry?) async -> HealthAnalysis {
        var analysis = HealthAnalysis()
        
        // Analyze BMI
        if let bmi = vitals?.BMI {
            analysis.bmiCategory = categorizeBMI(bmi)
            analysis.bmiRisk = assessBMIRisk(bmi)
        }
        
        // Analyze activity level
        if let activityLevel = vitals?.activity_level {
            analysis.activityLevel = categorizeActivityLevel(activityLevel)
        }
        
        // Analyze age and gender for recommendations
        if let dob = vitals?.date_of_birth, let gender = vitals?.gender {
            let age = calculateAge(from: dob)
            analysis.ageGroup = categorizeAge(age)
            analysis.gender = gender
        }
        
        // Analyze current goals
        if let goalType = vitals?.life_goal_type {
            analysis.currentGoal = goalType
        }
        
        // Analyze progress patterns
        analysis.progressPatterns = await analyzeProgressPatterns()
        
        return analysis
    }
    
    private func generateGoalSuggestions(analysis: HealthAnalysis) -> [GoalSuggestion] {
        var suggestions: [GoalSuggestion] = []
        
        // BMI-based suggestions
        if let bmiCategory = analysis.bmiCategory {
            switch bmiCategory {
            case .underweight:
                suggestions.append(GoalSuggestion(
                    category: .healthLongevity,
                    type: "Gain healthy weight",
                    priority: .high,
                    reasoning: "Your BMI indicates you're underweight. Focus on healthy weight gain.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            case .overweight, .obese:
                suggestions.append(GoalSuggestion(
                    category: .confidenceBody,
                    type: "Lose weight sustainably",
                    priority: .high,
                    reasoning: "Your BMI suggests weight loss would improve health and confidence.",
                    timeline: .sixMonths,
                    commitment: .dedicated
                ))
            case .normal:
                suggestions.append(GoalSuggestion(
                    category: .energyVitality,
                    type: "Maintain and improve fitness",
                    priority: .medium,
                    reasoning: "Great BMI! Focus on building strength and energy.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            }
        }
        
        // Activity level suggestions
        if let activityLevel = analysis.activityLevel {
            switch activityLevel {
            case .sedentary:
                suggestions.append(GoalSuggestion(
                    category: .energyVitality,
                    type: "Increase daily activity",
                    priority: .high,
                    reasoning: "Start with gentle activities to build energy levels.",
                    timeline: .oneMonth,
                    commitment: .casual
                ))
            case .light:
                suggestions.append(GoalSuggestion(
                    category: .energyVitality,
                    type: "Build consistent activity",
                    priority: .medium,
                    reasoning: "Great start! Build on your light activity routine.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            case .moderate:
                suggestions.append(GoalSuggestion(
                    category: .confidenceBody,
                    type: "Build strength and tone",
                    priority: .medium,
                    reasoning: "Great activity level! Add strength training for better results.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            case .active:
                suggestions.append(GoalSuggestion(
                    category: .healthLongevity,
                    type: "Optimize performance",
                    priority: .medium,
                    reasoning: "Excellent activity! Focus on recovery and optimization.",
                    timeline: .threeMonths,
                    commitment: .dedicated
                ))
            case .veryActive:
                suggestions.append(GoalSuggestion(
                    category: .healthLongevity,
                    type: "Elite performance",
                    priority: .low,
                    reasoning: "Outstanding activity level! Focus on recovery and fine-tuning.",
                    timeline: .threeMonths,
                    commitment: .dedicated
                ))
            }
        }
        
        // Age-based suggestions
        if let ageGroup = analysis.ageGroup {
            switch ageGroup {
            case .youngAdult:
                suggestions.append(GoalSuggestion(
                    category: .socialLifestyle,
                    type: "Build sustainable habits",
                    priority: .medium,
                    reasoning: "Perfect time to establish lifelong healthy habits.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            case .adult:
                suggestions.append(GoalSuggestion(
                    category: .stressWellness,
                    type: "Balance work and wellness",
                    priority: .high,
                    reasoning: "Focus on stress management and work-life balance.",
                    timeline: .threeMonths,
                    commitment: .moderate
                ))
            case .senior:
                suggestions.append(GoalSuggestion(
                    category: .healthLongevity,
                    type: "Maintain mobility and strength",
                    priority: .high,
                    reasoning: "Focus on maintaining mobility and preventing age-related decline.",
                    timeline: .sixMonths,
                    commitment: .moderate
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Predictions
    
    func generatePredictions(for goal: SmartGoal) async {
        var newPredictions: [GoalPrediction] = []
        
        // Weight loss predictions
        if goal.category == .confidenceBody && goal.type.contains("weight") {
            let weightPredictions = await predictWeightLoss(goal: goal)
            newPredictions.append(contentsOf: weightPredictions)
        }
        
        // Energy level predictions
        if goal.category == .energyVitality {
            let energyPredictions = await predictEnergyImprovement(goal: goal)
            newPredictions.append(contentsOf: energyPredictions)
        }
        
        // Stress reduction predictions
        if goal.category == .stressWellness {
            let stressPredictions = await predictStressReduction(goal: goal)
            newPredictions.append(contentsOf: stressPredictions)
        }
        
        await MainActor.run {
            self.predictions = newPredictions
        }
        
        logger.debug("Generated \(newPredictions.count) predictions for goal: \(goal.type)")
    }
    
    private func predictWeightLoss(goal: SmartGoal) async -> [GoalPrediction] {
        var predictions: [GoalPrediction] = []
        
        // Week 2 prediction
        predictions.append(GoalPrediction(
            title: "Week 2: Initial Changes",
            description: "You'll likely notice improved energy and reduced bloating",
            probability: 0.85,
            timeframe: "2 weeks",
            metric: "Energy Level",
            predictedValue: "+15%",
            confidence: 0.8
        ))
        
        // Month 1 prediction
        predictions.append(GoalPrediction(
            title: "Month 1: Visible Progress",
            description: "Expected weight loss of 2-4 kg with consistent effort",
            probability: 0.75,
            timeframe: "1 month",
            metric: "Weight Loss",
            predictedValue: "3 kg",
            confidence: 0.7
        ))
        
        // Month 3 prediction
        predictions.append(GoalPrediction(
            title: "Month 3: Significant Results",
            description: "Expected weight loss of 8-12 kg with lifestyle transformation",
            probability: 0.65,
            timeframe: "3 months",
            metric: "Weight Loss",
            predictedValue: "10 kg",
            confidence: 0.6
        ))
        
        return predictions
    }
    
    private func predictEnergyImprovement(goal: SmartGoal) async -> [GoalPrediction] {
        var predictions: [GoalPrediction] = []
        
        predictions.append(GoalPrediction(
            title: "Week 1: Better Sleep",
            description: "Improved sleep quality and morning energy",
            probability: 0.8,
            timeframe: "1 week",
            metric: "Sleep Quality",
            predictedValue: "+20%",
            confidence: 0.75
        ))
        
        predictions.append(GoalPrediction(
            title: "Month 1: Sustained Energy",
            description: "Consistent energy throughout the day",
            probability: 0.7,
            timeframe: "1 month",
            metric: "Daily Energy",
            predictedValue: "+30%",
            confidence: 0.65
        ))
        
        return predictions
    }
    
    private func predictStressReduction(goal: SmartGoal) async -> [GoalPrediction] {
        var predictions: [GoalPrediction] = []
        
        predictions.append(GoalPrediction(
            title: "Week 2: Reduced Anxiety",
            description: "Noticeable decrease in stress and anxiety levels",
            probability: 0.75,
            timeframe: "2 weeks",
            metric: "Stress Level",
            predictedValue: "-25%",
            confidence: 0.7
        ))
        
        return predictions
    }
    
    // MARK: - Milestone Tracking
    
    func trackMilestones(for goal: SmartGoal) async {
        let milestones = generateMilestones(for: goal)
        
        await MainActor.run {
            self.milestones = milestones
        }
        
        // Check for achieved milestones
        await checkMilestoneAchievements(goal: goal)
    }
    
    private func generateMilestones(for goal: SmartGoal) -> [GoalMilestone] {
        var milestones: [GoalMilestone] = []
        
        switch goal.category {
        case .confidenceBody:
            milestones = [
                GoalMilestone(id: "1", title: "First Week Complete", description: "Complete your first week of the program", isAchieved: false, targetDate: Date().addingTimeInterval(7*24*60*60)),
                GoalMilestone(id: "2", title: "First Month", description: "Complete one month of consistent effort", isAchieved: false, targetDate: Date().addingTimeInterval(30*24*60*60)),
                GoalMilestone(id: "3", title: "Noticeable Changes", description: "See visible improvements in your body", isAchieved: false, targetDate: Date().addingTimeInterval(45*24*60*60)),
                GoalMilestone(id: "4", title: "Confidence Boost", description: "Feel more confident in your appearance", isAchieved: false, targetDate: Date().addingTimeInterval(90*24*60*60))
            ]
        case .energyVitality:
            milestones = [
                GoalMilestone(id: "1", title: "Better Sleep", description: "Improve sleep quality and duration", isAchieved: false, targetDate: Date().addingTimeInterval(7*24*60*60)),
                GoalMilestone(id: "2", title: "Morning Energy", description: "Wake up feeling refreshed and energetic", isAchieved: false, targetDate: Date().addingTimeInterval(14*24*60*60)),
                GoalMilestone(id: "3", title: "Sustained Energy", description: "Maintain energy throughout the day", isAchieved: false, targetDate: Date().addingTimeInterval(30*24*60*60))
            ]
        default:
            milestones = [
                GoalMilestone(id: "1", title: "Get Started", description: "Begin your wellness journey", isAchieved: false, targetDate: Date().addingTimeInterval(7*24*60*60)),
                GoalMilestone(id: "2", title: "Build Habits", description: "Establish consistent healthy habits", isAchieved: false, targetDate: Date().addingTimeInterval(21*24*60*60)),
                GoalMilestone(id: "3", title: "See Results", description: "Notice positive changes in your life", isAchieved: false, targetDate: Date().addingTimeInterval(60*24*60*60))
            ]
        }
        
        return milestones
    }
    
    private func checkMilestoneAchievements(goal: SmartGoal) async {
        // This would check actual progress data and mark milestones as achieved
        // For now, we'll simulate some achievements
        await MainActor.run {
            for i in 0..<self.milestones.count {
                if self.milestones[i].targetDate < Date() && !self.milestones[i].isAchieved {
                    self.milestones[i].isAchieved = true
                    
                    // Create achievement
                    let achievement = GoalAchievement(
                        id: "milestone_\(self.milestones[i].id)",
                        title: "Milestone Achieved: \(self.milestones[i].title)",
                        description: self.milestones[i].description,
                        type: .milestone,
                        dateAchieved: Date(),
                        points: 100
                    )
                    self.achievements.append(achievement)
                }
            }
        }
    }
    
    // MARK: - Achievement System
    
    func checkForNewAchievements() async {
        var newAchievements: [GoalAchievement] = []
        
        // Check for various achievement types
        let stepAchievements = await checkStepAchievements()
        let weightAchievements = await checkWeightAchievements()
        let consistencyAchievements = await checkConsistencyAchievements()
        
        newAchievements.append(contentsOf: stepAchievements)
        newAchievements.append(contentsOf: weightAchievements)
        newAchievements.append(contentsOf: consistencyAchievements)
        
        await MainActor.run {
            self.achievements.append(contentsOf: newAchievements)
        }
        
        logger.debug("Found \(newAchievements.count) new achievements")
    }
    
    private func checkStepAchievements() async -> [GoalAchievement] {
        var achievements: [GoalAchievement] = []
        
        do {
            let steps = try await healthService.getSteps(date: Date())
            
            if steps >= 10000 {
                achievements.append(GoalAchievement(
                    id: "steps_10k",
                    title: "Step Master",
                    description: "Achieved 10,000 steps in a day",
                    type: .daily,
                    dateAchieved: Date(),
                    points: 50
                ))
            }
            
            if steps >= 15000 {
                achievements.append(GoalAchievement(
                    id: "steps_15k",
                    title: "Step Champion",
                    description: "Achieved 15,000 steps in a day",
                    type: .daily,
                    dateAchieved: Date(),
                    points: 100
                ))
            }
        } catch {
            logger.error("Failed to check step achievements: \(error)")
        }
        
        return achievements
    }
    
    private func checkWeightAchievements() async -> [GoalAchievement] {
        let achievements: [GoalAchievement] = []
        
        // This would check weight loss progress
        // For now, return empty array
        return achievements
    }
    
    private func checkConsistencyAchievements() async -> [GoalAchievement] {
        let achievements: [GoalAchievement] = []
        
        // This would check consistency in following the program
        // For now, return empty array
        return achievements
    }
    
    // MARK: - Progress Insights
    
    func generateProgressInsights() async {
        var insights: [ProgressInsight] = []
        
        // Generate insights based on current progress
        let progressInsight = await analyzeProgress()
        insights.append(progressInsight)
        
        // Generate motivational insights
        let motivationalInsight = generateMotivationalInsight()
        insights.append(motivationalInsight)
        
        await MainActor.run {
            self.progressInsights = insights
        }
    }
    
    private func analyzeProgress() async -> ProgressInsight {
        // This would analyze actual progress data
        // For now, return a generic insight
        return ProgressInsight(
            title: "Great Progress!",
            message: "You're on track to achieve your goals. Keep up the excellent work!",
            type: GoalInsightType.positive,
            icon: "star.fill"
        )
    }
    
    private func generateMotivationalInsight() -> ProgressInsight {
        return ProgressInsight(
            title: "Stay Motivated",
            message: "Remember why you started. Every small step brings you closer to your goal.",
            type: GoalInsightType.motivational,
            icon: "heart.fill"
        )
    }
    
    private func createSmartGoalRecommendations(suggestions: [GoalSuggestion], analysis: HealthAnalysis) async {
        // Create a SmartGoal from the user's current life goal
        if let currentGoalType = analysis.currentGoal {
            let smartGoal = SmartGoal(
                id: UUID().uuidString,
                category: determineCategory(from: currentGoalType),
                type: currentGoalType,
                priority: .high,
                reasoning: "Personalized goal based on your current life goal and health metrics",
                timeline: .threeMonths,
                commitment: .moderate,
                startDate: Date(),
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                progress: 0.0,
                isActive: true
            )
            
            await MainActor.run {
                self.currentGoal = smartGoal
            }
            
            logger.debug("Set current goal: \(currentGoalType)")
            
            // Generate predictions and milestones for the current goal
            await generatePredictions(for: smartGoal)
            await trackMilestones(for: smartGoal)
        }
        
        logger.debug("Created \(suggestions.count) smart goal recommendations")
    }
    
    private func determineCategory(from goalType: String) -> LifeGoalCategory {
        let lowercased = goalType.lowercased()
        
        if lowercased.contains("weight") || lowercased.contains("confidence") || lowercased.contains("clothes") {
            return .confidenceBody
        } else if lowercased.contains("energy") || lowercased.contains("vitality") {
            return .energyVitality
        } else if lowercased.contains("stress") || lowercased.contains("wellness") || lowercased.contains("manage") {
            return .stressWellness
        } else if lowercased.contains("health") || lowercased.contains("longevity") {
            return .healthLongevity
        } else if lowercased.contains("social") || lowercased.contains("lifestyle") {
            return .socialLifestyle
        } else {
            return .energyVitality // Default
        }
    }
    
    // MARK: - Actionable Recommendations
    
    func generateDailyActions(for goal: SmartGoal, tdee: Double? = nil, weight: Double? = nil) async -> [DailyAction] {
        var actions: [DailyAction] = []
        
        // Get actual user goals from ProfileViewModel
        let userGoals = await getUserGoals()
        
        switch goal.category {
        case .confidenceBody:
            if goal.type.contains("weight") || goal.type.contains("confidence") {
                actions.append(contentsOf: generateWeightLossActions(goal: goal, tdee: tdee, weight: weight, userGoals: userGoals))
            }
            actions.append(contentsOf: generateFitnessActions(goal: goal, userGoals: userGoals))
            
        case .energyVitality:
            actions.append(contentsOf: generateEnergyActions(goal: goal, userGoals: userGoals))
            actions.append(contentsOf: generateHydrationActions(goal: goal, userGoals: userGoals))
            
        case .stressWellness:
            actions.append(contentsOf: generateStressReductionActions(goal: goal))
            actions.append(contentsOf: generateSleepActions(goal: goal, userGoals: userGoals))
            
        case .healthLongevity:
            actions.append(contentsOf: generateHealthActions(goal: goal, userGoals: userGoals))
            actions.append(contentsOf: generateNutritionActions(goal: goal, userGoals: userGoals))
            
        case .socialLifestyle:
            actions.append(contentsOf: generateSocialActions(goal: goal))
            actions.append(contentsOf: generateLifestyleActions(goal: goal))
        }
        
        return actions
    }
    
    private func getUserGoals() async -> (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float) {
        do {
            guard let userId = authRepository.authState.userId else {
                return (10000, 2.5, 2000, 3, 8.0)
            }
            
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            guard let vitals = vitalsResponse.data.first else {
                return (10000, 2.5, 2000, 3, 8.0)
            }
            
            return (
                stepGoal: vitals.stepGoal ?? 10000,
                waterGoal: vitals.waterGoal ?? 2.5,
                calorieGoal: vitals.calorieGoal ?? 2000,
                mealGoal: vitals.mealGoal ?? 3,
                sleepGoal: vitals.sleepGoal ?? 8.0
            )
            
        } catch {
            logger.error("Failed to fetch user goals: \(error)")
            return (10000, 2.5, 2000, 3, 8.0)
        }
    }
    
    private func generateWeightLossActions(goal: SmartGoal, tdee: Double? = nil, weight: Double? = nil, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        // Calculate daily calorie deficit based on goal
        let weeklyDeficit: Double = goal.timeline == .threeMonths ? 3500.0 : 1750.0 // 0.5kg vs 0.25kg per week
        let dailyDeficit = weeklyDeficit / 7.0
        
        // TDEE-based calorie target
        let actualTDEE = tdee ?? calculateTDEE(for: goal)
        let calorieTarget = actualTDEE - dailyDeficit
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Daily Calories",
            description: "Stay within \(Int(calorieTarget)) calories for weight loss",
            target: "\(Int(calorieTarget))",
            current: "0",
            unit: "calories",
            type: .nutrition,
            priority: .high,
            icon: "flame.fill",
            color: .orange
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Daily Steps",
            description: "Walk at least \(userGoals.stepGoal) steps to burn calories",
            target: "\(userGoals.stepGoal)",
            current: "0",
            unit: "steps",
            type: .activity,
            priority: .high,
            icon: "figure.walk",
            color: .blue
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Strength Training",
            description: "Do 30 minutes of strength training",
            target: "30",
            current: "0",
            unit: "minutes",
            type: .exercise,
            priority: .medium,
            icon: "dumbbell.fill",
            color: .purple
        ))
        
        // Meal planning actions
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Balanced Meals",
            description: "Eat \(userGoals.mealGoal) balanced meals with protein, carbs, and healthy fats",
            target: "\(userGoals.mealGoal)",
            current: "0",
            unit: "meals",
            type: .nutrition,
            priority: .high,
            icon: "fork.knife",
            color: .green
        ))
        
        let proteinTarget = calculateProteinTarget(for: goal, weight: weight)
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Protein Intake",
            description: "Consume \(proteinTarget)g protein for muscle health",
            target: "\(proteinTarget)",
            current: "0",
            unit: "grams",
            type: .nutrition,
            priority: .medium,
            icon: "leaf.fill",
            color: .green
        ))
        
        return actions
    }
    
    private func calculateTDEE(for goal: SmartGoal) -> Double {
        // This would use the actual user's TDEE from ProfileViewModel
        // For now, using a default calculation
        let bmr = 2000.0 // This should come from ProfileViewModel
        let activityMultiplier = 1.375 // Moderate activity
        return bmr * activityMultiplier
    }
    
    private func calculateProteinTarget(for goal: SmartGoal, weight: Double? = nil) -> Int {
        // Protein target based on weight and goal
        let actualWeight = weight ?? 70.0 // This should come from ProfileViewModel
        return Int(actualWeight * 1.6) // 1.6g per kg for weight loss
    }
    
    private func generateEnergyActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Hydration Goal",
            description: "Drink enough water to maintain energy levels",
            target: "\(userGoals.waterGoal)",
            current: "0",
            unit: "ml",
            type: .hydration,
            priority: .high,
            icon: "drop.fill",
            color: .blue
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Morning Exercise",
            description: "Start your day with 20 minutes of light exercise",
            target: "20",
            current: "0",
            unit: "minutes",
            type: .exercise,
            priority: .medium,
            icon: "sunrise.fill",
            color: .orange
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Sleep Quality",
            description: "Get 7-8 hours of quality sleep tonight",
            target: "\(userGoals.sleepGoal)",
            current: "0",
            unit: "hours",
            type: .sleep,
            priority: .high,
            icon: "bed.double.fill",
            color: .indigo
        ))
        
        return actions
    }
    
    private func generateStressReductionActions(goal: SmartGoal) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Meditation",
            description: "Practice 15 minutes of mindfulness meditation",
            target: "15",
            current: "0",
            unit: "minutes",
            type: .mindfulness,
            priority: .high,
            icon: "brain.head.profile",
            color: .purple
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Deep Breathing",
            description: "Take 10 deep breathing breaks throughout the day",
            target: "10",
            current: "0",
            unit: "sessions",
            type: .mindfulness,
            priority: .medium,
            icon: "lungs.fill",
            color: .green
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Nature Walk",
            description: "Spend 30 minutes outdoors in nature",
            target: "30",
            current: "0",
            unit: "minutes",
            type: .activity,
            priority: .medium,
            icon: "leaf.fill",
            color: .green
        ))
        
        return actions
    }
    
    private func generateFitnessActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Cardio Exercise",
            description: "Complete 45 minutes of cardio training",
            target: "45",
            current: "0",
            unit: "minutes",
            type: .exercise,
            priority: .high,
            icon: "heart.fill",
            color: .red
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Daily Steps",
            description: "Achieve your daily step goal",
            target: "\(userGoals.stepGoal)",
            current: "0",
            unit: "steps",
            type: .activity,
            priority: .high,
            icon: "figure.walk",
            color: .blue
        ))
        
        return actions
    }
    
    private func generateHydrationActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        // Convert water goal from liters to ml
        let waterGoalML = Int(userGoals.waterGoal * 1000)
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Daily Hydration",
            description: "Drink \(waterGoalML)ml of water for optimal health",
            target: "\(waterGoalML)",
            current: "0",
            unit: "ml",
            type: .hydration,
            priority: .high,
            icon: "drop.fill",
            color: .blue
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Morning Hydration",
            description: "Drink 500ml of water within 30 minutes of waking up",
            target: "500",
            current: "0",
            unit: "ml",
            type: .hydration,
            priority: .medium,
            icon: "sunrise.fill",
            color: .blue
        ))
        
        return actions
    }
    
    private func generateSleepActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Sleep Schedule",
            description: "Get \(String(format: "%.1f", userGoals.sleepGoal)) hours of quality sleep tonight",
            target: String(format: "%.1f", userGoals.sleepGoal),
            current: "0",
            unit: "hours",
            type: .sleep,
            priority: .high,
            icon: "bed.double.fill",
            color: .indigo
        ))
        
        return actions
    }
    
    private func generateHealthActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Balanced Nutrition",
            description: "Eat a balanced meal with protein, carbs, and healthy fats",
            target: "\(userGoals.mealGoal)",
            current: "0",
            unit: "meals",
            type: .nutrition,
            priority: .high,
            icon: "fork.knife",
            color: .orange
        ))
        
        return actions
    }
    
    private func generateNutritionActions(goal: SmartGoal, userGoals: (stepGoal: Int, waterGoal: Float, calorieGoal: Int, mealGoal: Int, sleepGoal: Float)) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        // Calculate personalized protein target
        let proteinTarget = calculateProteinTarget(for: goal, weight: nil)
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Protein Intake",
            description: "Consume \(proteinTarget)g protein for muscle health",
            target: "\(proteinTarget)",
            current: "0",
            unit: "grams",
            type: .nutrition,
            priority: .high,
            icon: "leaf.fill",
            color: .green
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Balanced Meals",
            description: "Eat \(userGoals.mealGoal) balanced meals with protein, carbs, and healthy fats",
            target: "\(userGoals.mealGoal)",
            current: "0",
            unit: "meals",
            type: .nutrition,
            priority: .high,
            icon: "fork.knife",
            color: .orange
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Vegetable Intake",
            description: "Eat at least 5 servings of vegetables",
            target: "5",
            current: "0",
            unit: "servings",
            type: .nutrition,
            priority: .medium,
            icon: "carrot.fill",
            color: .green
        ))
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Fruit Intake",
            description: "Eat at least 2 servings of fruits",
            target: "2",
            current: "0",
            unit: "servings",
            type: .nutrition,
            priority: .medium,
            icon: "applelogo",
            color: .red
        ))
        
        return actions
    }
    
    private func generateSocialActions(goal: SmartGoal) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Social Connection",
            description: "Connect with a friend or family member",
            target: "1",
            current: "0",
            unit: "connections",
            type: .social,
            priority: .medium,
            icon: "person.2.fill",
            color: .pink
        ))
        
        return actions
    }
    
    private func generateLifestyleActions(goal: SmartGoal) -> [DailyAction] {
        var actions: [DailyAction] = []
        
        actions.append(DailyAction(
            id: UUID().uuidString,
            title: "Hobby Time",
            description: "Spend time on a hobby or passion project",
            target: "30",
            current: "0",
            unit: "minutes",
            type: .lifestyle,
            priority: .low,
            icon: "star.fill",
            color: .yellow
        ))
        
        return actions
    }
    
    // MARK: - Status Check
    func checkInitializationStatus() async -> Bool {
        guard let userId = authRepository.authState.userId else {
            logger.error("No user ID available for smart goals")
            return false
        }
        
        do {
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            let vitals = vitalsResponse.data.first
            
            // Check if user has set a life goal
            let hasLifeGoal = vitals?.life_goal_type != nil && vitals?.life_goal_category != nil
            
            if !hasLifeGoal {
                logger.info("User has not set a life goal yet")
                return false
            }
            
            // Check if we have basic health data
            let hasBasicData = vitals?.WeightInKilograms != nil || vitals?.height != nil
            
            if !hasBasicData {
                logger.info("User missing basic health data (weight/height)")
                return false
            }
            
            logger.info("Smart goals properly initialized with life goal: \(vitals?.life_goal_type ?? "unknown")")
            return true
            
        } catch {
            logger.error("Failed to check smart goals initialization: \(error.localizedDescription)")
            return false
        }
    }
    
    func initialize() async {
        isLoading = true
        defer { isLoading = false }
        
        await initializeSmartGoalsIfNeeded()
    }
    
    func initializeSmartGoalsIfNeeded() async {
        let isInitialized = await checkInitializationStatus()
        
        if !isInitialized {
            logger.info("Initializing smart goals system...")
            await analyzeUserProfileAndSuggestGoals()
        } else {
            logger.info("Smart goals already initialized")
            // Generate daily actions for existing goal
            if let currentGoal = self.currentGoal {
                let actions = await generateDailyActions(for: currentGoal)
                await MainActor.run {
                    self.dailyActions = actions
                }
                logger.info("Generated \(actions.count) daily actions for existing goal")
            }
        }
    }
    
    func updateDailyActions() async {
        guard let currentGoal = self.currentGoal else {
            logger.warning("No current goal available for daily actions")
            return
        }
        
        // Get actual user data for more accurate targets
        let tdee = await getActualTDEE()
        let weight = await getActualWeight()
        
        let actions = await generateDailyActions(for: currentGoal, tdee: tdee, weight: weight)
        await MainActor.run {
            self.dailyActions = actions
            self.lastActionDate = Date()
        }
        logger.info("Updated daily actions: \(actions.count) actions with TDEE: \(tdee ?? 0), Weight: \(weight ?? 0)")
    }
    
    func forceRefreshDailyActions() async {
        logger.info("Force refreshing daily actions...")
        await resetDailyActionsForNewDay()
        await updateActionProgress()
    }
    
    func getDailyActionsStatus() -> String {
        let completedActions = dailyActions.filter { $0.isCompleted }.count
        let totalActions = dailyActions.count
        let completionRate = totalActions > 0 ? Double(completedActions) / Double(totalActions) * 100 : 0
        
        return "\(completedActions)/\(totalActions) actions completed (\(Int(completionRate))%)"
    }
    
    func getTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    func updateActionProgress() async {
        guard !dailyActions.isEmpty else { return }
        
        // Update action progress with real data
        for i in 0..<dailyActions.count {
            var action = dailyActions[i]
            
            switch action.type {
            case .activity:
                // Update steps
                if action.title.contains("Steps") {
                    do {
                        let steps = try await healthService.getSteps(date: Date())
                        action.current = "\(steps)"
                    } catch {
                        logger.warning("Failed to fetch steps: \(error)")
                    }
                }
                
            case .hydration:
                // Update hydration
                if action.title.contains("Water") || action.title.contains("Hydration") {
                    do {
                        let hydration = try await healthService.getHydration(date: Date())
                        action.current = "\(Int(hydration * 1000))" // Convert to ml
                    } catch {
                        logger.warning("Failed to fetch hydration: \(error)")
                    }
                }
                
            case .nutrition:
                // Update nutrition data (meals, protein, etc.)
                if action.title.contains("Meals") || action.title.contains("Balanced") {
                    // For now, we'll need to implement meal tracking
                    // This could come from diet logs or user input
                    action.current = "0" // Placeholder
                } else if action.title.contains("Protein") {
                    // Protein tracking would need to be implemented
                    action.current = "0" // Placeholder
                } else if action.title.contains("Vegetable") || action.title.contains("Fruit") {
                    // Fruit/vegetable tracking would need to be implemented
                    action.current = "0" // Placeholder
                }
                
            case .exercise:
                // Update exercise time
                if action.title.contains("Exercise") || action.title.contains("Training") {
                    do {
                        let calories = try await healthService.getCaloriesBurned(date: Date())
                        // Estimate exercise time based on calories (rough approximation)
                        let estimatedMinutes = Int(calories / 10) // 10 calories per minute average
                        action.current = "\(estimatedMinutes)"
                    } catch {
                        logger.warning("Failed to fetch exercise data: \(error)")
                    }
                }
                
            default:
                break
            }
            
            // Update completion status
            action.isCompleted = action.progress >= 1.0
            
            // Update the action in the array
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if i < self.dailyActions.count {
                    self.dailyActions[i] = action
                }
            }
        }
        
        logger.info("Updated action progress for \(self.dailyActions.count) actions")
    }
    
    func updateSmartGoalProgress() async {
        guard var currentGoal = self.currentGoal else { return }
        
        // Calculate progress based on current data vs targets
        var totalProgress: Double = 0.0
        var completedActions = 0
        
        for action in dailyActions {
            if action.isCompleted {
                completedActions += 1
            }
            totalProgress += action.progress
        }
        
        let averageProgress = dailyActions.isEmpty ? 0.0 : totalProgress / Double(dailyActions.count)
        let completionRate = dailyActions.isEmpty ? 0.0 : Double(completedActions) / Double(dailyActions.count)
        
        // Update the current goal progress
        currentGoal.progress = averageProgress
        
        await MainActor.run {
            self.currentGoal = currentGoal
        }
        
        logger.info("Updated smart goal progress: \(Int(averageProgress * 100))% (completion rate: \(Int(completionRate * 100))%)")
    }
    
    func refreshSmartGoalsData() async {
        logger.info("Refreshing smart goals data...")
        
        // Re-analyze user profile and generate new goals
        await analyzeUserProfileAndSuggestGoals()
        
        // Update daily actions for current goal with actual TDEE and weight data
        if let currentGoal = self.currentGoal {
            // Get actual TDEE and weight from ProfileViewModel
            let tdee = await getActualTDEE()
            let weight = await getActualWeight()
            
            let actions = await generateDailyActions(for: currentGoal, tdee: tdee, weight: weight)
            await MainActor.run {
                self.dailyActions = actions
            }
            logger.info("Refreshed daily actions: \(actions.count) actions with TDEE: \(tdee ?? 0), Weight: \(weight ?? 0)")
        }
        
        // Update action progress with real data
        await updateActionProgress()
        
        logger.info("Smart goals data refresh completed")
    }
    
    private func getActualTDEE() async -> Double? {
        do {
            guard let userId = authRepository.authState.userId else {
                logger.warning("No user ID available for TDEE calculation")
                return nil
            }
            
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            guard let vitals = vitalsResponse.data.first else {
                logger.warning("No health vitals found for TDEE calculation")
                return nil
            }
            
            // Calculate TDEE based on user's actual data
            if let weight = vitals.WeightInKilograms,
               let height = vitals.height,
               let gender = vitals.gender,
               let dob = vitals.date_of_birth,
               let activityLevel = vitals.activity_level {
                
                let age = calculateAge(from: dob)
                let bmr = calculateBMR(weight: Double(weight), height: Double(height), age: age, gender: gender)
                let activityMultiplier = getActivityMultiplier(activityLevel: activityLevel)
                let tdee = bmr * activityMultiplier
                
                logger.info("Calculated TDEE: \(tdee) (BMR: \(bmr), Activity: \(activityMultiplier))")
                return tdee
            }
            
            logger.warning("Missing data for TDEE calculation")
            return nil
            
        } catch {
            logger.error("Failed to fetch TDEE data: \(error)")
            return nil
        }
    }
    
    private func getActualWeight() async -> Double? {
        do {
            guard let userId = authRepository.authState.userId else {
                logger.warning("No user ID available for weight data")
                return nil
            }
            
            let vitalsResponse = try await strapiRepository.getHealthVitals(userId: userId)
            guard let vitals = vitalsResponse.data.first,
                  let weight = vitals.WeightInKilograms else {
                logger.warning("No weight data found")
                return nil
            }
            
            logger.info("Fetched actual weight: \(weight)")
            return Double(weight)
            
        } catch {
            logger.error("Failed to fetch weight data: \(error)")
            return nil
        }
    }
    
    private func calculateBMR(weight: Double, height: Double, age: Int, gender: String) -> Double {
        // Mifflin-St Jeor Equation
        let bmr: Double
        if gender.lowercased() == "male" {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        return bmr
    }
    
    private func getActivityMultiplier(activityLevel: String) -> Double {
        switch activityLevel {
        case "Sedentary (little/no exercise)": return 1.2
        case "Light exercise (1-3 days/week)": return 1.375
        case "Moderate exercise (3-5 days/week)": return 1.55
        case "Heavy exercise (6-7 days/week)": return 1.725
        case "Very heavy exercise (Twice/day)": return 1.9
        default: return 1.375
        }
    }
    
    // MARK: - Helper Methods
    
    private func categorizeBMI(_ bmi: Double) -> BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25: return .normal
        case 25..<30: return .overweight
        default: return .obese
        }
    }
    
    private func assessBMIRisk(_ bmi: Double) -> RiskLevel {
        switch bmi {
        case ..<18.5: return .medium
        case 18.5..<25: return .low
        case 25..<30: return .medium
        default: return .high
        }
    }
    
    private func categorizeActivityLevel(_ level: String) -> ActivityCategory {
        switch level {
        case "Sedentary (little/no exercise)": return .sedentary
        case "Light exercise (1-3 days/week)": return .light
        case "Moderate exercise (3-5 days/week)": return .moderate
        case "Heavy exercise (6-7 days/week)": return .active
        case "Very heavy exercise (Twice/day)": return .veryActive
        default: return .moderate
        }
    }
    
    private func calculateAge(from dobString: String) -> Int {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dobString) else { return 30 }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 30
    }
    
    private func categorizeAge(_ age: Int) -> AgeGroup {
        switch age {
        case 18..<30: return .youngAdult
        case 30..<60: return .adult
        default: return .senior
        }
    }
    
    private func analyzeProgressPatterns() async -> [String] {
        // This would analyze historical progress data
        // For now, return empty array
        return []
    }
}

// MARK: - Data Models

struct SmartGoal {
    let id: String
    let category: LifeGoalCategory
    let type: String
    let priority: GoalPriority
    let reasoning: String
    let timeline: GoalTimeline
    let commitment: GoalCommitmentLevel
    let startDate: Date
    let targetDate: Date
    var progress: Double
    let isActive: Bool
}

struct GoalPrediction {
    let title: String
    let description: String
    let probability: Double
    let timeframe: String
    let metric: String
    let predictedValue: String
    let confidence: Double
}

struct GoalMilestone {
    let id: String
    let title: String
    let description: String
    var isAchieved: Bool
    let targetDate: Date
}

struct GoalAchievement {
    let id: String
    let title: String
    let description: String
    let type: AchievementType
    let dateAchieved: Date
    let points: Int
}

struct ProgressInsight {
    let title: String
    let message: String
    let type: GoalInsightType
    let icon: String
}

struct GoalSuggestion {
    let category: LifeGoalCategory
    let type: String
    let priority: GoalPriority
    let reasoning: String
    let timeline: GoalTimeline
    let commitment: GoalCommitmentLevel
}

struct HealthAnalysis {
    var bmiCategory: BMICategory?
    var bmiRisk: RiskLevel?
    var activityLevel: ActivityCategory?
    var ageGroup: AgeGroup?
    var gender: String?
    var currentGoal: String?
    var progressPatterns: [String] = []
}

enum BMICategory {
    case underweight, normal, overweight, obese
}

enum RiskLevel {
    case low, medium, high
}

enum ActivityCategory {
    case sedentary, light, moderate, active, veryActive
}

enum AgeGroup {
    case youngAdult, adult, senior
}

enum GoalPriority {
    case low, medium, high
}

enum AchievementType {
    case daily, weekly, monthly, milestone, special
}

enum GoalInsightType {
    case positive, negative, motivational, warning
}

// MARK: - Daily Action Models

struct DailyAction {
    let id: String
    let title: String
    let description: String
    let target: String
    var current: String
    let unit: String
    let type: ActionType
    let priority: ActionPriority
    let icon: String
    let color: ActionColor
    var isCompleted: Bool = false
    var progress: Double {
        guard let targetValue = Double(target), let currentValue = Double(current) else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
}

enum ActionType {
    case nutrition, activity, exercise, hydration, sleep, mindfulness, social, lifestyle
}

enum ActionPriority {
    case low, medium, high
}

enum ActionColor {
    case red, orange, yellow, green, blue, indigo, purple, pink
    
    func toColor() -> Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }
} 
