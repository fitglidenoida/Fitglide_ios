import Foundation
import Combine

class WorkoutPlanService: ObservableObject {
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    @Published var availablePlans: [WorkoutEntry] = []
    @Published var userPlans: [WorkoutEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Plan Management
    
    @MainActor
    func fetchAvailablePlans() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = authRepository.authState.userId else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let response = try await strapiRepository.getWorkoutPlans(userId: userId)
            availablePlans = response.data.filter { $0.isTemplate == true }
            
            print("📋 Fetched \(availablePlans.count) available workout plans")
        } catch {
            errorMessage = "Failed to fetch plans: \(error.localizedDescription)"
            print("❌ Error fetching plans: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchUserPlans() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = authRepository.authState.userId else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let response = try await strapiRepository.getWorkoutPlans(userId: userId)
            userPlans = response.data.filter { $0.isTemplate == false }
            
            print("👤 Fetched \(userPlans.count) user workout plans")
        } catch {
            errorMessage = "Failed to fetch user plans: \(error.localizedDescription)"
            print("❌ Error fetching user plans: \(error)")
        }
        
        isLoading = false
    }
    
    func startWorkoutPlan(plan: WorkoutEntry) async {
        // Implementation for starting a workout plan
        print("🚀 Starting workout plan: \(plan.title)")
    }
    
    func getPlansByCategory(_ category: String) -> [WorkoutEntry] {
        return availablePlans.filter { $0.planCategory == category }
    }
    
    func getFreePlans() -> [WorkoutEntry] {
        return availablePlans.filter { $0.isPremium == false }
    }
    
    func getPremiumPlans() -> [WorkoutEntry] {
        return availablePlans.filter { $0.isPremium == true }
    }
} 