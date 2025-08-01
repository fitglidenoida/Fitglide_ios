//
//  AppleAuthManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import Foundation
import OSLog

// MARK: - Token Manager Protocol (Not used in current implementation)
protocol TokenManager {
    var currentToken: String? { get }
    func refreshTokenIfNeeded() async throws
}

// MARK: - Secure Token Manager Implementation
class SecureTokenManager: TokenManager {
    private let keychainManager: KeychainManager
    private let logger = Logger(subsystem: "com.TrailBlazeWellness.Fitglide-ios", category: "SecureTokenManager")
    
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }
    
    var currentToken: String? {
        get {
            return keychainManager.loadString(forKey: KeychainManager.KeychainKeys.jwtToken)
        }
    }
    
    func refreshTokenIfNeeded() async throws {
        // Implement token refresh logic here
        // This would typically check if the token is expired and refresh it
        logger.debug("Token refresh requested")
    }
    
    func storeToken(_ token: String) throws {
        let success = keychainManager.saveString(token, forKey: KeychainManager.KeychainKeys.jwtToken)
        if success {
            logger.debug("Token stored securely in keychain")
        } else {
            throw NSError(domain: "SecureTokenManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to store token"])
        }
    }
    
    func clearToken() throws {
        let success = keychainManager.deleteString(forKey: KeychainManager.KeychainKeys.jwtToken)
        if success {
            logger.debug("Token cleared from keychain")
        } else {
            throw NSError(domain: "SecureTokenManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to clear token"])
        }
    }
}

// MARK: - StrapiApi Protocol
protocol StrapiApi {
    // Health Logs
    func postHealthLog(body: HealthLogBody, token: String) async throws -> HealthLogResponse
    func updateHealthLog(id: String, body: HealthLogBody, token: String) async throws -> HealthLogResponse
    func getHealthLog(filters: [String: String], token: String) async throws -> HealthLogListResponse
    
    // Sleep Logs
    func getSleepLog(filters: [String: String], token: String) async throws -> SleepLogListResponse
    func postSleepLog(body: SleepLogRequest, token: String) async throws -> SleepLogResponse
    func updateSleepLog(id: String, body: SleepLogRequest, token: String) async throws -> SleepLogResponse
    
    // Workouts
    func postWorkout(body: WorkoutRequest, token: String) async throws -> WorkoutResponse
    func updateWorkout(id: String, body: WorkoutRequest, token: String) async throws -> WorkoutResponse
    func getWorkouts(filters: [String: String], token: String) async throws -> WorkoutListResponse
    
    func postWorkoutLog(body: WorkoutLogRequest, token: String) async throws -> WorkoutLogResponse
    func updateWorkoutLog(documentId: String, body: WorkoutLogRequest, token: String) async throws -> WorkoutLogResponse
    func getWorkoutLogs(filters: [String: String], token: String) async throws -> WorkoutLogListResponse
    
    // Health Vitals
    func getHealthVitals(userId: String, populate: String, token: String) async throws -> HealthVitalsListResponse
    func postHealthVitals(body: HealthVitalsRequest, token: String) async throws -> HealthVitalsResponse
    func updateHealthVitals(id: String, body: HealthVitalsRequest, token: String) async throws -> HealthVitalsResponse

    // Weight Loss Stories
    func getWeightLossStories(populate: String, token: String) async throws -> WeightLossStoryListResponse
    func getWeightLossStoriesForUser(userId: String, populate: String, token: String) async throws -> WeightLossStoryListResponse
    func postWeightLossStory(body: WeightLossStoryRequest, token: String) async throws -> WeightLossStoryResponse
    func updateWeightLossStory(id: String, body: WeightLossStoryRequest, token: String) async throws -> WeightLossStoryResponse
    
    // User Profile
    func getUserProfile(token: String) async throws -> UserProfileResponse
    func updateUserProfile(id: String, body: UserProfileRequest, token: String) async throws -> UserProfileResponse
    
    // Meals
    func postCustomMealRequest(body: CustomMealRequest, token: String) async throws -> CustomMealResponse
    func postMealGoal(body: MealGoalRequest, token: String) async throws -> MealGoalResponse
    func getDietPlan(userId: String, mealDate: String?, populate: String, token: String) async throws -> DietPlanListResponse
    func getDietComponents(type: String, pageSize: Int, page: Int, token: String) async throws -> DietComponentListResponse
    func postDietPlan(body: DietPlanRequest, token: String) async throws -> DietPlanResponse
    func updateDietPlan(documentId: String, body: DietPlanRequest, token: String) async throws -> DietPlanResponse
    func postMeal(body: MealRequest, token: String) async throws -> MealResponse
    func updateMeal(documentId: String, body: MealRequest, token: String) async throws -> MealResponse
    func getDietLogs(userId: String, date: String, token: String) async throws -> Data
    func postDietLog(body: DietLogRequest, token: String) async throws -> DietLogResponse
    func putDietLog(documentId: String, body: DietLogUpdateRequest, token: String) async throws -> DietLogResponse
    func postFeedback(body: FeedbackRequest, token: String) async throws -> FeedbackResponse
    
    // Social Features
    func getPacks(userId: String, token: String) async throws -> PackListResponse
    func postPack(body: PackRequest, token: String) async throws -> PackResponse
    func updatePack(id: String, body: PackRequest, token: String) async throws -> PackResponse
    func joinPack(request: PackJoinRequest, token: String) async throws -> PackResponse
    
    func getPosts(packId: Int?, token: String) async throws -> PostListResponse
    func postPost(body: PostRequest, token: String) async throws -> PostResponse
    
    func getCheers(userId: String, token: String) async throws -> CheerListResponse
    func postCheer(body: CheerRequest, token: String) async throws -> CheerResponse
    
    func getChallenges(userId: String, token: String) async throws -> ChallengeListResponse
    func postChallenge(body: ChallengeRequest, token: String) async throws -> ChallengeResponse
    func updateChallenge(id: String, body: ChallengeRequest, token: String) async throws -> ChallengeResponse
    func getAcceptedChallenges(userId: String, token: String) async throws -> ChallengeListResponse
    func joinChallenge(request: ChallengeJoinRequest, token: String) async throws -> ChallengeResponse

    func getFriends(filters: [String: String], token: String) async throws -> FriendListResponse
    func postFriend(body: FriendRequest, token: String) async throws -> FriendResponse
    func updateFriend(id: String, body: FriendRequest, token: String) async throws -> FriendResponse
    
    func getComments(postId: String, token: String) async throws -> CommentListResponse
    func postComment(body: CommentRequest, token: String) async throws -> CommentListResponse
    
    // Strava Integration
    func initiateStravaAuth(state: String, token: String) async throws -> StravaAuthResponse
    func stravaCallback(request: StravaCallbackRequest, token: String) async throws -> StravaCallbackResponse
    func exchangeStravaCode(request: StravaTokenRequest, token: String) async throws -> StravaTokenResponse
    func syncStravaActivities(perPage: Int, token: String) async throws -> WorkoutLogListResponse
    
    // Other Features
    func getDesiMessages(populate: String, token: String) async throws -> DesiMessageResponse
    func getBadges(populate: String, token: String) async throws -> BadgeListResponse
    func getExercises(pageSize: Int, page: Int, token: String) async throws -> ExerciseListResponse
    
    func postStepSession(body: StepSessionRequest, token: String) async throws -> StepSessionResponse
    func updateStepSession(id: String, body: StepSessionRequest, token: String) async throws -> StepSessionResponse
    func getStepSessions(filters: [String: String], token: String) async throws -> StepSessionListResponse

    // File Upload
    func uploadFile(file: URL, token: String) async throws -> [MediaData]
}

class StrapiApiClient: StrapiApi {
    private let baseURL = URL(string: "https://admin.fitglide.in/api/")!
    private let logger = Logger(subsystem: "com.TrailBlazeWellness.Fitglide-ios", category: "StrapiApiClient")
    
    init() {
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, token: String) async throws -> T {
        logger.debug("Sending authenticated request: \(request.httpMethod ?? "Unknown") \(request.url?.absoluteString ?? "No URL")")
        
        // Security: Validate token before using
        guard !token.isEmpty else {
            throw NSError(domain: "StrapiApi", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid or empty token"])
        }
        
        var authenticatedRequest = request
        authenticatedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Security: Add additional headers for security
        authenticatedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        authenticatedRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        return try await performRequestInternal(authenticatedRequest)
    }
    
    private func performRequestUnauthenticated<T: Codable>(_ request: URLRequest) async throws -> T {
        logger.debug("Sending unauthenticated request: \(request.httpMethod ?? "Unknown") \(request.url?.absoluteString ?? "No URL")")
        
        // Security: Add additional headers for security
        var secureRequest = request
        secureRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        secureRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        return try await performRequestInternal(secureRequest)
    }
    
    private func performRequestInternal<T: Codable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "StrapiApi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        // Security: Handle different HTTP status codes appropriately
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            break
        case 401:
            logger.error("Authentication failed - token may be invalid or expired")
            throw NSError(domain: "StrapiApi", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
        case 403:
            logger.error("Access forbidden")
            throw NSError(domain: "StrapiApi", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access forbidden"])
        case 429:
            logger.error("Rate limit exceeded")
            throw NSError(domain: "StrapiApi", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        case 500...599:
            logger.error("Server error: \(httpResponse.statusCode)")
            throw NSError(domain: "StrapiApi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        default:
            logger.error("Request failed with status code: \(httpResponse.statusCode)")
            throw NSError(domain: "StrapiApi", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed"])
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func buildRequest(method: String, path: String, queryItems: [URLQueryItem] = [], body: Codable? = nil, token: String? = nil) throws -> URLRequest {
        // Security: Validate input parameters
        guard !path.isEmpty else {
            throw NSError(domain: "StrapiApi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid path"])
        }
        
        // Security: Sanitize path to prevent path traversal attacks
        let sanitizedPath = path.replacingOccurrences(of: "..", with: "").replacingOccurrences(of: "//", with: "/")
        
        var components = URLComponents(url: baseURL.appendingPathComponent(sanitizedPath), resolvingAgainstBaseURL: true)!
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw NSError(domain: "StrapiApi", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Security: Add additional security headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-store", forHTTPHeaderField: "Pragma")
        
        if let token = token {
            // Security: Validate token format
            guard token.count > 10 else {
                throw NSError(domain: "StrapiApi", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid token format"])
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                logger.debug("Request body: \(jsonString)")
            }
        }
        return request
    }

    private func buildMultipartRequest(path: String, file: URL, token: String) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        let fileName = file.lastPathComponent
        let mimeType = "application/octet-stream" // Adjust based on file type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(try Data(contentsOf: file))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        return request
    }
    
    // Health Logs
    func postHealthLog(body: HealthLogBody, token: String) async throws -> HealthLogResponse {
        let request = try buildRequest(method: "POST", path: "health-logs", body: body, token: token)
        return try await performRequest(request, token: token)
    }

    func updateHealthLog(id: String, body: HealthLogBody, token: String) async throws -> HealthLogResponse {
        let request = try buildRequest(method: "PUT", path: "health-logs/\(id)", body: body, token: token)
        return try await performRequest(request, token: token)
    }

    
    func getHealthLog(filters: [String: String], token: String) async throws -> HealthLogListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "health-logs", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Sleep Logs
    func getSleepLog(filters: [String: String], token: String) async throws -> SleepLogListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "sleeplogs", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postSleepLog(body: SleepLogRequest, token: String) async throws -> SleepLogResponse {
        let wrappedBody = SleepLogBody(data: body)
        let request = try buildRequest(method: "POST", path: "sleeplogs", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateSleepLog(id: String, body: SleepLogRequest, token: String) async throws -> SleepLogResponse {
        let wrappedBody = SleepLogBody(data: body)
        let request = try buildRequest(method: "PUT", path: "sleeplogs/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Workouts (Plans)
    func postWorkout(body: WorkoutRequest, token: String) async throws -> WorkoutResponse {
        let wrappedBody = WorkoutBody(data: body)
        let request = try buildRequest(method: "POST", path: "workouts", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateWorkout(id: String, body: WorkoutRequest, token: String) async throws -> WorkoutResponse {
        let wrappedBody = WorkoutBody(data: body)
        let request = try buildRequest(method: "PUT", path: "workouts/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getWorkouts(filters: [String: String], token: String) async throws -> WorkoutListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "workouts", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Workout Logs
    func postWorkoutLog(body: WorkoutLogRequest, token: String) async throws -> WorkoutLogResponse {
        let wrappedBody = WorkoutLogBody(data: body)
        let request = try buildRequest(method: "POST", path: "workout-logs", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateWorkoutLog(documentId: String, body: WorkoutLogRequest, token: String) async throws -> WorkoutLogResponse {
        let wrappedBody = WorkoutLogBody(data: body)
        let request = try buildRequest(method: "PUT", path: "workout-logs/\(documentId)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getWorkoutLogs(filters: [String: String], token: String) async throws -> WorkoutLogListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "workout-logs", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Health Vitals
    func getHealthVitals(userId: String, populate: String, token: String) async throws -> HealthVitalsListResponse {
        let queryItems = [
            URLQueryItem(name: "filters[users_permissions_user][id][$eq]", value: userId),
            URLQueryItem(name: "populate", value: populate)
        ]
        let request = try buildRequest(method: "GET", path: "health-vitals", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postHealthVitals(body: HealthVitalsRequest, token: String) async throws -> HealthVitalsResponse {
        let wrappedBody = HealthVitalsBody(data: body)
        let request = try buildRequest(method: "POST", path: "health-vitals", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateHealthVitals(id: String, body: HealthVitalsRequest, token: String) async throws -> HealthVitalsResponse {
        let wrappedBody = HealthVitalsBody(data: body)
        let request = try buildRequest(method: "PUT", path: "health-vitals/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }

    // Weight Loss Stories
    func getWeightLossStories(populate: String, token: String) async throws -> WeightLossStoryListResponse {
        let queryItems = [URLQueryItem(name: "populate", value: populate)]
        let request = try buildRequest(method: "GET", path: "weight-loss-stories", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getWeightLossStoriesForUser(userId: String, populate: String, token: String) async throws -> WeightLossStoryListResponse {
        let queryItems = [
            URLQueryItem(name: "filters[users_permissions_user][id][$eq]", value: userId),
            URLQueryItem(name: "populate", value: populate)
        ]
        let request = try buildRequest(method: "GET", path: "weight-loss-stories", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postWeightLossStory(body: WeightLossStoryRequest, token: String) async throws -> WeightLossStoryResponse {
        let wrappedBody = WeightLossStoryBody(data: body)
        let request = try buildRequest(method: "POST", path: "weight-loss-stories", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateWeightLossStory(id: String, body: WeightLossStoryRequest, token: String) async throws -> WeightLossStoryResponse {
        let wrappedBody = WeightLossStoryBody(data: body)
        let request = try buildRequest(method: "PUT", path: "weight-loss-stories/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // User Profile
    func getUserProfile(token: String) async throws -> UserProfileResponse {
        let request = try buildRequest(method: "GET", path: "users/me", token: token)
        return try await performRequest(request, token: token)
    }

    func updateUserProfile(id: String, body: UserProfileRequest, token: String) async throws -> UserProfileResponse {
        let request = try buildRequest(method: "PUT", path: "users/\(id)", body: body, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Meals and Diet
    func postCustomMealRequest(body: CustomMealRequest, token: String) async throws -> CustomMealResponse {
        let wrappedBody = CustomMealRequestBody(data: body)
        let request = try buildRequest(method: "POST", path: "custom-meal-requests", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postMealGoal(body: MealGoalRequest, token: String) async throws -> MealGoalResponse {
        let wrappedBody = MealGoalBody(data: body)
        let request = try buildRequest(method: "POST", path: "meal-goals", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getDietPlan(userId: String, mealDate: String?, populate: String, token: String) async throws -> DietPlanListResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "filters[users_permissions_user][id][$eq]", value: userId),
            URLQueryItem(name: "filters[active][$eq]",                     value: "true"), // <- NEW
            URLQueryItem(name: "populate",                                 value: populate)
        ]

        if let d = mealDate {
            queryItems.append(
                URLQueryItem(
                    name: "filters[meals][meal_date][$eq]",
                    value: d
                )
            )
        }

        let request = try buildRequest(
            method:     "GET",
            path:       "diet-plans",
            queryItems: queryItems,
            token:      token
        )
        return try await performRequest(request, token: token)
    }

    
    func getDietComponents(type: String, pageSize: Int, page: Int, token: String) async throws -> DietComponentListResponse {
        let queryItems = [
            URLQueryItem(name: "filters[food_type][$eq]", value: type),
            URLQueryItem(name: "pagination[pageSize]", value: "\(pageSize)"),
            URLQueryItem(name: "pagination[page]", value: "\(page)")
        ]
        let request = try buildRequest(method: "GET", path: "diet-components", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postDietPlan(body: DietPlanRequest, token: String) async throws -> DietPlanResponse {
        let wrappedBody = DietPlanBody(data: body)
        let request = try buildRequest(method: "POST", path: "diet-plans", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateDietPlan(documentId: String, body: DietPlanRequest, token: String) async throws -> DietPlanResponse {
        let wrappedBody = DietPlanBody(data: body)
        let request = try buildRequest(method: "PUT", path: "diet-plans/\(documentId)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postMeal(body: MealRequest, token: String) async throws -> MealResponse {
        let wrappedBody = MealBody(data: body)
        let request = try buildRequest(method: "POST", path: "meals", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateMeal(documentId: String, body: MealRequest, token: String) async throws -> MealResponse {
        let wrappedBody = MealBody(data: body)
        let request = try buildRequest(method: "PUT", path: "meals/\(documentId)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getDietLogs(userId: String, date: String, token: String) async throws -> Data {
            let queryItems = [
                URLQueryItem(name: "filters[users_permissions_user][id][$eq]", value: userId),
                URLQueryItem(name: "filters[date][$eq]", value: date)
            ]
            let request = try buildRequest(method: "GET", path: "diet-logs", queryItems: queryItems, token: token)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.debug("Received response with status code: \(httpResponse.statusCode)")
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.debug("Raw response data: \(jsonString)")
            } else {
                logger.error("Failed to convert response data to string")
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                logger.error("Request failed with status code: \((response as? HTTPURLResponse)?.statusCode ?? -1), body: \(errorBody)")
                throw NSError(domain: "", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Request failed: \(errorBody)"])
            }
            
            return data
        }
    
    func postDietLog(body: DietLogRequest, token: String) async throws -> DietLogResponse {
        let wrappedBody = DietLogBody(data: body)
        let request = try buildRequest(method: "POST", path: "diet-logs", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func putDietLog(documentId: String, body: DietLogUpdateRequest, token: String) async throws -> DietLogResponse {
        let wrappedBody = DietLogUpdateBody(data: body)
        let request = try buildRequest(method: "PUT", path: "diet-logs/\(documentId)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postFeedback(body: FeedbackRequest, token: String) async throws -> FeedbackResponse {
        let wrappedBody = FeedbackBody(data: body)
        let request = try buildRequest(method: "POST", path: "meal-feedbacks", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Packs
    func getPacks(userId: String, token: String) async throws -> PackListResponse {
        let queryItems = [URLQueryItem(name: "filters[gliders][id][$eq]", value: userId)]
        let request = try buildRequest(method: "GET", path: "packs", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postPack(body: PackRequest, token: String) async throws -> PackResponse {
        let wrappedBody = PackBody(data: body)
        let request = try buildRequest(method: "POST", path: "packs", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updatePack(id: String, body: PackRequest, token: String) async throws -> PackResponse {
        let wrappedBody = PackBody(data: body)
        let request = try buildRequest(method: "PUT", path: "packs/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func joinPack(request: PackJoinRequest, token: String) async throws -> PackResponse {
        let request = try buildRequest(method: "POST", path: "packs/join", body: request, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Posts
    func getPosts(packId: Int?, token: String) async throws -> PostListResponse {
        var queryItems: [URLQueryItem] = []

        if let id = packId {
            queryItems.append(URLQueryItem(name: "filters[pack][id][$eq]", value: "\(id)"))
        }

        let request = try buildRequest(
            method: "GET",
            path: "posts",
            queryItems: queryItems,
            token: token
        )

        return try await performRequest(request, token: token)
    }

    func postPost(body: PostRequest, token: String) async throws -> PostResponse {
        let wrappedBody = PostBody(data: body)
        let request = try buildRequest(method: "POST", path: "posts", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Cheers
    func getCheers(userId: String, token: String) async throws -> CheerListResponse {
        let queryItems = [URLQueryItem(name: "filters[receiver][id][$eq]", value: userId)]
        let request = try buildRequest(method: "GET", path: "cheers", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postCheer(body: CheerRequest, token: String) async throws -> CheerResponse {
        let wrappedBody = CheerBody(data: body)
        let request = try buildRequest(method: "POST", path: "cheers", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Challenges
    // Challenges
    func getChallenges(userId: String, token: String) async throws -> ChallengeListResponse {
        let queryItems = [URLQueryItem(name: "filters[challengerId][id][$eq]", value: userId)]
        let request = try buildRequest(method: "GET", path: "challenges", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getAcceptedChallenges(userId: String, token: String) async throws -> ChallengeListResponse {
        let queryItems = [
            URLQueryItem(name: "filters[$or][0][challengerId][id][$eq]", value: userId),
            URLQueryItem(name: "filters[$or][1][challengeeId][id][$eq]", value: userId),
            URLQueryItem(name: "filters[challenge_status][$eq]", value: "accepted")
        ]
        let request = try buildRequest(method: "GET", path: "challenges", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postChallenge(body: ChallengeRequest, token: String) async throws -> ChallengeResponse {
        let wrappedBody = ChallengeBody(data: body)
        let request = try buildRequest(method: "POST", path: "challenges", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateChallenge(id: String, body: ChallengeRequest, token: String) async throws -> ChallengeResponse {
        let wrappedBody = ChallengeBody(data: body)
        let request = try buildRequest(method: "PUT", path: "challenges/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func joinChallenge(request: ChallengeJoinRequest, token: String) async throws -> ChallengeResponse {
        let request = try buildRequest(method: "POST", path: "challenges/join", body: request, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Friends
    func getFriends(filters: [String: String], token: String) async throws -> FriendListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "friends", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postFriend(body: FriendRequest, token: String) async throws -> FriendResponse {
        let wrappedBody = FriendBody(data: body)
        let request = try buildRequest(method: "POST", path: "friends", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    func updateFriend(id: String, body: FriendRequest, token: String) async throws -> FriendResponse {
        let wrappedBody = FriendBody(data: body)
        let request = try buildRequest(method: "PUT", path: "friends/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Comments
    func getComments(postId: String, token: String) async throws -> CommentListResponse {
        let queryItems = [URLQueryItem(name: "filters[post][id][$eq]", value: postId)]
        let request = try buildRequest(method: "GET", path: "comments", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postComment(body: CommentRequest, token: String) async throws -> CommentListResponse {
        let request = try buildRequest(method: "POST", path: "comments", body: body, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Strava Integration
    func initiateStravaAuth(state: String, token: String) async throws -> StravaAuthResponse {
        let queryItems = [URLQueryItem(name: "state", value: state)]
        let request = try buildRequest(method: "GET", path: "strava-auth", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func stravaCallback(request: StravaCallbackRequest, token: String) async throws -> StravaCallbackResponse {
        let request = try buildRequest(method: "POST", path: "strava-callback", body: request, token: token)
        return try await performRequest(request, token: token)
    }
    
    func exchangeStravaCode(request: StravaTokenRequest, token: String) async throws -> StravaTokenResponse {
        let request = try buildRequest(method: "POST", path: "strava/token", body: request, token: token)
        return try await performRequest(request, token: token)
    }
    
    func syncStravaActivities(perPage: Int, token: String) async throws -> WorkoutLogListResponse {
        let queryItems = [URLQueryItem(name: "per_page", value: "\(perPage)")]
        let request = try buildRequest(method: "GET", path: "strava/sync-activities", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    // Desi Messages and Badges
    func getDesiMessages(populate: String, token: String) async throws -> DesiMessageResponse {
        let queryItems = [URLQueryItem(name: "populate", value: populate)]
        let request = try buildRequest(method: "GET", path: "desi-messages", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getBadges(populate: String, token: String) async throws -> BadgeListResponse {
        let queryItems = [URLQueryItem(name: "populate", value: populate)]
        let request = try buildRequest(method: "GET", path: "badges", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func getExercises(pageSize: Int, page: Int, token: String) async throws -> ExerciseListResponse {
        let queryItems = [
            URLQueryItem(name: "pagination[pageSize]", value: "\(pageSize)"),
            URLQueryItem(name: "pagination[page]", value: "\(page)")
        ]
        let request = try buildRequest(method: "GET", path: "exercises", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
    func uploadFile(file: URL, token: String) async throws -> [MediaData] {
        let request = try buildMultipartRequest(path: "upload", file: file, token: token)
        return try await performRequest(request, token: token)
    }
    
    func postStepSession(body: StepSessionRequest, token: String) async throws -> StepSessionResponse {
        let wrappedBody = StepSessionBody(data: body)
        let request = try buildRequest(method: "POST", path: "step-sessions", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }

    func updateStepSession(id: String, body: StepSessionRequest, token: String) async throws -> StepSessionResponse {
        let wrappedBody = StepSessionBody(data: body)
        let request = try buildRequest(method: "PUT", path: "step-sessions/\(id)", body: wrappedBody, token: token)
        return try await performRequest(request, token: token)
    }

    func getStepSessions(filters: [String: String], token: String) async throws -> StepSessionListResponse {
        let queryItems = filters.map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = try buildRequest(method: "GET", path: "step-sessions", queryItems: queryItems, token: token)
        return try await performRequest(request, token: token)
    }
    
}

// Data Models
struct HealthVitalsBody: Codable {
    let data: HealthVitalsRequest
}

struct HealthVitalsRequest: Codable {
    let WeightInKilograms: Int?
    let height: Int?
    let gender: String?
    let date_of_birth: String?
    let activity_level: String?
    let weight_loss_goal: Int?
    let stepGoal: Int?
    let waterGoal: Float?
    let calorieGoal: Int?
    let weight_loss_strategy: String?
    let users_permissions_user: UserId?
    let BMI:  Double?        // allow decimals like 26.5
    let BMR:  Double?
    
    enum CodingKeys: String, CodingKey {
        case WeightInKilograms
        case height
        case gender
        case date_of_birth
        case activity_level
        case weight_loss_goal
        case stepGoal
        case waterGoal
        case calorieGoal
        case weight_loss_strategy
        case users_permissions_user
        case BMI
        case BMR
    }
}

struct HealthVitalsResponse: Codable {
    let data: HealthVitalsEntry
}

struct HealthVitalsListResponse: Codable {
    let data: [HealthVitalsEntry]
    let meta: Meta?
}

struct HealthVitalsEntry: Codable {
    let id: Int
    let documentId: String
    let vitalid: String?
    let WeightInKilograms: Int?
    let BMR: Double?
    let BMI: Double?
    let PercentFat: Float?
    let weight_loss_goal: Int?
    let gender: String?
    let height: Int?
    let date_of_birth: String?
    let stepGoal: Int?
    let waterGoal: Float?
    let calorieGoal: Int?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let weekly_target_calculated: String?
    let weight_loss_strategy: String?
    let activity_level: String?
    let users_permissions_user: UserProfileResponse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case vitalid
        case WeightInKilograms
        case BMR
        case BMI
        case PercentFat
        case weight_loss_goal
        case gender
        case height
        case date_of_birth
        case stepGoal
        case waterGoal
        case calorieGoal
        case createdAt
        case updatedAt
        case publishedAt
        case weekly_target_calculated
        case weight_loss_strategy
        case activity_level
        case users_permissions_user
    }
}

struct HealthLogRequest: Codable {
    let dateTime: String?
    let steps: Int64?
    let waterIntake: Float?
    let heartRate: Int64?
    let caloriesBurned: Float?
    let source: String?
    let usersPermissionsUser: UserId?
    
    enum CodingKeys: String, CodingKey {
        case dateTime
        case steps
        case waterIntake
        case heartRate
        case caloriesBurned
        case source
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct HealthLogBody: Codable {
    let data: HealthLogRequest
}

struct HealthLogResponse: Codable {
    let data: HealthLogEntry
}

struct HealthLogListResponse: Codable {
    let data: [HealthLogEntry]
}

//struct HealthLogEntryBody: Codable {
//    let data: HealthLogEntry
//}

struct HealthLogEntry: Codable {
    let documentId: String?
    let dateTime: String
    let steps: Int64?
    let waterIntake: Float?
    let heartRate: Int64?
    let caloriesBurned: Float?
    let source: String?
    let usersPermissionsUser: UserId?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case dateTime
        case steps
        case waterIntake
        case heartRate
        case caloriesBurned
        case source
        case usersPermissionsUser = "users_permissions_user"
        case createdAt
    }
}

struct SleepLogRequest: Codable {
    let date: String
    let sleepDuration: Float
    let deepSleepDuration: Float
    let remSleepDuration: Float
    let lightSleepDuration: Float
    let sleepAwakeDuration: Float
    let startTime: String?
    let endTime: String?
    let usersPermissionsUser: UserId
    
    enum CodingKeys: String, CodingKey {
        case date
        case sleepDuration = "sleep_duration"
        case deepSleepDuration = "deep_sleep_duration"
        case remSleepDuration = "rem_sleep_duration"
        case lightSleepDuration = "light_sleep_duration"
        case sleepAwakeDuration = "sleep_awake_duration"
        case startTime
        case endTime
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct SleepLogBody: Codable {
    let data: SleepLogRequest
}

struct SleepLogResponse: Codable {
    let data: SleepLogEntry
}

struct SleepLogListResponse: Codable {
    let data: [SleepLogEntry]
}

struct SleepLogEntry: Codable {
    let id: Int
    let documentId: String
    let sleepLogId: String?
    let sleepDuration: Float
    let deepSleepDuration: Float
    let remSleepDuration: Float
    let lightSleepDuration: Float
    let sleepAwakeDuration: Float
    let date: String
    let startTime: Date?
    let endTime: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let publishedAt: Date?
    let usersPermissionsUser: UserEntry?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case sleepLogId = "sleep_log_id"
        case sleepDuration = "sleep_duration"
        case deepSleepDuration = "deep_sleep_duration"
        case remSleepDuration = "rem_sleep_duration"
        case lightSleepDuration = "light_sleep_duration"
        case sleepAwakeDuration = "sleep_awake_duration"
        case date
        case startTime
        case endTime
        case createdAt
        case updatedAt
        case publishedAt
        case usersPermissionsUser = "users_permissions_user"
    }

    // Custom decoder to handle ISO 8601 format with fractional seconds
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        documentId = try container.decode(String.self, forKey: .documentId)
        sleepLogId = try container.decodeIfPresent(String.self, forKey: .sleepLogId)
        sleepDuration = try container.decode(Float.self, forKey: .sleepDuration)
        deepSleepDuration = try container.decode(Float.self, forKey: .deepSleepDuration)
        remSleepDuration = try container.decode(Float.self, forKey: .remSleepDuration)
        lightSleepDuration = try container.decode(Float.self, forKey: .lightSleepDuration)
        sleepAwakeDuration = try container.decode(Float.self, forKey: .sleepAwakeDuration)
        date = try container.decode(String.self, forKey: .date)
        usersPermissionsUser = try container.decodeIfPresent(UserEntry.self, forKey: .usersPermissionsUser)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        func parseDate(for key: CodingKeys) -> Date? {
            if let string = try? container.decodeIfPresent(String.self, forKey: key) {
                return formatter.date(from: string)
            }
            return nil
        }

        startTime = parseDate(for: .startTime)
        endTime = parseDate(for: .endTime)
        createdAt = parseDate(for: .createdAt)
        updatedAt = parseDate(for: .updatedAt)
        publishedAt = parseDate(for: .publishedAt)
    }
}

struct UserEntry: Codable {
    let id: String
    let documentId: String
    let username: String
    let email: String
    let provider: String?
    let confirmed: Bool?
    let blocked: Bool?
    let type: String?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let firstName: String?
    let lastName: String?
    let picture: String?
    let googleId: String?
    let mobile: Int64?
    let notificationsEnabled: Bool?
    let maxGreetingsEnabled: Bool?
    let athleteId: Int?
    let stravaConnected: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case username
        case email
        case provider
        case confirmed
        case blocked
        case type
        case createdAt
        case updatedAt
        case publishedAt
        case firstName
        case lastName
        case picture
        case googleId
        case mobile
        case notificationsEnabled
        case maxGreetingsEnabled
        case athleteId = "athlete_id"
        case stravaConnected = "strava_connected"
    }
}

struct WorkoutRequest: Codable {
    let workoutId: String
    let title: String
    let description: String?
    let distancePlanned: Float
    let totalTimePlanned: Float
    let caloriesPlanned: Float
    let sportType: String
    let exercises: [ExerciseId]
    let exerciseOrder: [String]
    let isTemplate: Bool
    let usersPermissionsUser: UserId
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case workoutId
        case title = "Title"
        case description = "Description"
        case distancePlanned = "DistancePlanned"
        case totalTimePlanned = "TotalTimePlanned"
        case caloriesPlanned = "CaloriesPlanned"
        case sportType = "sport_type"
        case exercises
        case exerciseOrder = "exercise_order"
        case isTemplate = "is_template"
        case usersPermissionsUser = "users_permissions_user"
        case completed
    }
}

struct WorkoutBody: Codable {
    let data: WorkoutRequest
}

struct ExerciseId: Codable {
    let id: String
}

struct WorkoutResponse: Codable {
    let data: WorkoutEntry
}

struct WorkoutListResponse: Codable {
    let data: [WorkoutEntry]
}

struct WorkoutEntry: Codable {
    let id: String
    let documentId: String
    let workoutId: String
    let title: String
    let description: String?
    let distancePlanned: Float
    let totalTimePlanned: Float
    let caloriesPlanned: Float
    let sportType: String
    let dayNumber: Int
    let exercises: [ExerciseEntry]?
    let exerciseOrder: [String]?
    let isTemplate: Bool?
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case workoutId
        case title = "Title"
        case description = "Description"
        case distancePlanned = "DistancePlanned"
        case totalTimePlanned = "TotalTimePlanned"
        case caloriesPlanned = "CaloriesPlanned"
        case sportType = "sport_type"
        case dayNumber
        case exercises
        case exerciseOrder = "exercise_order"
        case isTemplate = "is_template"
        case completed
    }
}

struct ExerciseEntry: Codable {
    let id: Int
    let documentId: String
    let name: String?
    let description: String?
    let type: String?
    let duration: Float?
    let caloriesPerMinute: Float?
    let steps: String?
    let sportType: String?
    let reps: Int?
    let sets: Int?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let restBetweenSets: Int?
    let weight: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case name
        case description
        case type
        case duration
        case caloriesPerMinute = "calories_per_minute"
        case steps
        case sportType = "sport_type"
        case reps
        case sets
        case createdAt
        case updatedAt
        case publishedAt
        case restBetweenSets = "rest_between_sets"
        case weight
    }
}

struct WorkoutLogRequest: Codable {
    let logId: String
    let workout: UserId?
    let startTime: String
    let endTime: String
    let distance: Float
    let totalTime: Float
    let calories: Float
    let heartRateAverage: Int64
    let heartRateMaximum: Int64
    let heartRateMinimum: Int64
    let route: [[String: Float]]
    let completed: Bool
    let notes: String
    let usersPermissionsUser: UserId
    
    enum CodingKeys: String, CodingKey {
        case logId
        case workout
        case startTime
        case endTime
        case distance = "Distance"
        case totalTime = "TotalTime"
        case calories = "Calories"
        case heartRateAverage = "HeartRateAverage"
        case heartRateMaximum = "HeartRateMaximum"
        case heartRateMinimum = "HeartRateMinimum"
        case route
        case completed
        case notes
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct WorkoutLogBody: Codable {
    let data: WorkoutLogRequest
}

struct WorkoutLogResponse: Codable {
    let data: WorkoutLogEntry
}

struct WorkoutLogListResponse: Codable {
    let data: [WorkoutLogEntry]
}

struct WorkoutLogEntry: Codable {
    let id: String
    let documentId: String
    let logId: String
    let workout: UserId?
    let startTime: String
    let endTime: String
    let distance: Float?
    let totalTime: Float?
    let calories: Float?
    let heartRateAverage: Int64?
    let heartRateMaximum: Int64?
    let heartRateMinimum: Int64?
    let route: [[String: Float]]?
    let completed: Bool
    let notes: String?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case logId
        case workout
        case startTime
        case endTime
        case distance = "Distance"
        case totalTime = "TotalTime"
        case calories = "Calories"
        case heartRateAverage = "HeartRateAverage"
        case heartRateMaximum = "HeartRateMaximum"
        case heartRateMinimum = "HeartRateMinimum"
        case route
        case completed
        case notes
        case type
    }
}

struct WeightLossStoryRequest: Codable {
    let storyId: String
    let thenWeight: Double
    let nowWeight: Double
    let weightLost: Double
    let storyText: String
    let usersPermissionsUser: UserId
    let visibility: String
    let beforeImage: MediaId?
    let afterImage: MediaId?
    
    enum CodingKeys: String, CodingKey {
        case storyId
        case thenWeight
        case nowWeight
        case weightLost
        case storyText
        case usersPermissionsUser = "users_permissions_user"
        case visibility
        case beforeImage
        case afterImage
    }
}

struct WeightLossStoryBody: Codable {
    let data: WeightLossStoryRequest
}

struct WeightLossStoryResponse: Codable {
    let data: WeightLossStoryEntry
}

struct WeightLossStoryListResponse: Codable {
    let data: [WeightLossStoryEntry]
}

struct WeightLossStoryEntry: Codable {
    let id: Int
    let documentId: String
    let storyId: String?
    let thenWeight: Double?
    let nowWeight: Double?
    let weightLost: Double?
    let storyText: String?
    let likes: Int?
    let visibility: String?
    let usersPermissionsUser: UserEntry?
    let beforeImage: MediaData?
    let afterImage: MediaData?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case storyId
        case thenWeight
        case nowWeight
        case weightLost
        case storyText
        case likes
        case visibility
        case usersPermissionsUser = "users_permissions_user"
        case beforeImage
        case afterImage
        case createdAt
        case updatedAt
        case publishedAt
    }
}

struct MediaId: Codable {
    let id: String
}

struct UserProfileResponse: Codable {
    let id: Int
    let documentId: String
    let username: String
    let email: String
    let provider: String?
    let confirmed: Bool?
    let blocked: Bool?
    let type: String?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let firstName: String?
    let lastName: String?
    let picture: String?
    let googleId: String?
    let mobile: Int64?
    let notificationsEnabled: Bool?
    let maxGreetingsEnabled: Bool?
    let athleteId: Int?
    let stravaConnected: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case username
        case email
        case provider
        case confirmed
        case blocked
        case type
        case createdAt
        case updatedAt
        case publishedAt
        case firstName
        case lastName
        case picture
        case googleId
        case mobile
        case notificationsEnabled
        case maxGreetingsEnabled
        case athleteId = "athlete_id"
        case stravaConnected = "strava_connected"
    }
}

struct UserProfileRequest: Codable {
    let username: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let mobile: Int64?
    let notificationsEnabled: Bool?
    let maxGreetingsEnabled: Bool?
    let athleteId: Int?
    let stravaConnected: Bool?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName
        case lastName
        case email
        case mobile
        case notificationsEnabled
        case maxGreetingsEnabled
        case athleteId = "athlete_id"
        case stravaConnected = "strava_connected"
    }
}


struct CustomMealRequest: Codable {
    let userId: String
    let food: String
    
    enum CodingKeys: String, CodingKey {
        case userId
        case food
    }
}

struct CustomMealRequestBody: Codable {
    let data: CustomMealRequest
}

struct CustomMealResponse: Codable {
    let data: [String: AnyCodable]
}

struct MealGoalRequest: Codable {
    let userId: String
    let meal: String
    let calories: Float
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case userId
        case meal
        case calories
        case time
    }
}

struct MealGoalBody: Codable {
    let data: MealGoalRequest
}

struct MealGoalResponse: Codable {
    let data: [String: AnyCodable]
}

struct DietPlanRequest: Codable {
    let planId: String
    let totalCalories: Int
    let dietPreference: String
    let active: Bool
    let pointsEarned: Int
    let dietGoal: String
    let meals: [String]
    let usersPermissionsUser: UserId
    
    enum CodingKeys: String, CodingKey {
        case planId = "plan_id"
        case totalCalories = "total_calories"
        case dietPreference = "diet_preference"
        case active
        case pointsEarned = "points_earned"
        case dietGoal = "diet_goal"
        case meals
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct DietPlanBody: Codable {
    let data: DietPlanRequest
}

struct DietPlanListResponse: Codable {
    let data: [DietPlanEntry]
}

struct DietPlanResponse: Codable {
    let data: DietPlanEntry
}

struct DietPlanEntry: Codable {
    let documentId: String
    let planId: String
    let totalCalories: Int
    let dietPreference: String
    let active: Bool
    let pointsEarned: Int
    let dietGoal: String
    let meals: [MealEntry]?
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case planId = "plan_id"
        case totalCalories = "total_calories"
        case dietPreference = "diet_preference"
        case active
        case pointsEarned = "points_earned"
        case dietGoal = "diet_goal"
        case meals
    }
}

struct MealRequest: Codable {
    let name: String
    let mealTime: String          // "HH:mm:ss"
    let basePortion: Int
    let basePortionUnit: String   //  ← NEW
    let totalCalories: Int
    let mealDate: String
    let dietComponents: [String]? // component documentIds
    
    enum CodingKeys: String, CodingKey {
        case name
        case mealTime        = "meal_time"
        case basePortion     = "base_portion"
        case basePortionUnit = "base_portion_unit"
        case totalCalories
        case mealDate        = "meal_date"
        case dietComponents  = "diet_components"
    }
}

struct MealBody: Codable {
    let data: MealRequest
}

struct MealResponse: Codable {
    let data: MealEntry
}

struct MealEntry: Codable {
    let documentId: String
    let name: String
    let mealTime: String
    let basePortion: Int
    let totalCalories: Int
    let mealDate: String
    let dietComponents: [DietComponentEntry]?
    
    enum CodingKeys: String, CodingKey {
        case documentId
        case name
        case mealTime = "meal_time"
        case basePortion = "base_portion"
        case totalCalories
        case mealDate = "meal_date"
        case dietComponents = "diet_components"
    }
}

struct DietComponentListResponse: Codable {
    let data: [DietComponentEntry]
}


struct DietComponentEntry: Codable, Identifiable, Hashable {
    let id:             Int
    let documentId:     String?         // "documentId" in JSON
    let name:           String          // always present → non-optional
    let category:       String?
    let calories:       Int?            // Int in JSON
    let foodType:       String?         // food_type in JSON ("Veg"/"Non-Veg")

    // macronutrients come in as strings like "1.12g"
    let protein:        String?
    let carbohydrate:   String?
    let totalFat:       String?         // total_fat in JSON
    let fiber:          String?

    // when Strapi has "Lunch, Dinner" we keep the raw strings
    let mealSuitRaw:    [String]?       // meal_suitability in JSON

    // serving info
    let portionSize:    Int?            // portion_size in JSON (100 = per-100 g)
    let unit:           String?         // "gm", "Cup", …

    // MARK: – CodingKeys to bridge snake-case → camelCase
    enum CodingKeys: String, CodingKey {
        case id, documentId, name, category, calories
        case foodType       = "food_type"
        case protein, carbohydrate
        case totalFat       = "total_fat"
        case fiber
        case mealSuitRaw    = "meal_suitability"
        case portionSize    = "portion_size"
        case unit
    }
}

struct DecodedMealLogEntry: Decodable {
    let mealId: String
    let components: [DecodedComponentLogEntry]
}

struct DecodedComponentLogEntry: Decodable {
    let componentId: String
    let consumed: Bool
}

struct DietLogRequest: Codable {
    let date: String
    let usersPermissionsUser: UserId
    let meals: [MealLogEntry]
    
    enum CodingKeys: String, CodingKey {
        case date
        case usersPermissionsUser = "users_permissions_user"
        case meals
    }
}

struct DietLogUpdateRequest: Codable {
    let date: String
    let meals: [MealLogEntry]
}

struct DietLogBody: Codable {
    let data: DietLogRequest
}

struct DietLogUpdateBody: Codable {
    let data: DietLogUpdateRequest
}

struct DietLogListResponse: Codable {
    let data: [DietLogEntry]
}

struct DietLogResponse: Codable {
    let data: DietLogEntry
}

struct DietLogEntry: Codable {
    let id: Int
    let documentId: String
    let date: String
    let meals: [MealLogEntry]? // Use MealLogEntry instead of [[String: Any]]
}

struct MealLogEntry: Codable {
    let mealId: String
    let components: [ComponentLogEntry]
}

struct ComponentLogEntry: Codable {
    let componentId: String
    let consumed: Bool
}

struct FeedbackRequest: Codable {
    let userId: String
    let mealId: String
    let oldComponentId: String
    let newComponentId: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case userId
        case mealId
        case oldComponentId
        case newComponentId
        case timestamp
    }
}

struct FeedbackBody: Codable {
    let data: FeedbackRequest
}

struct FeedbackResponse: Codable {
    let data: [String: AnyCodable]
}

struct PackRequest: Codable {
    let name: String
    let goal: Int
    let gliders: [UserId]
    let captain: UserId
    let description: String?
    let visibility: String?   // "public", "private"
    let logo: MediaId?
}


struct PackBody: Codable {
    let data: PackRequest
}

struct PackId: Codable {
    let id: String
}

struct PackResponse: Codable {
    let data: PackEntry
}

struct PackListResponse: Codable {
    let data: [PackEntry]
}

struct PackEntry: Codable, Hashable {
    let id: Int
    let name: String
    let goal: Int
    let progress: Int
    let gliders: [UserId]?
    let captain: UserId?
    let description: String?
    let visibility: String?
    let logo: MediaData?
}

struct PostRequest: Codable {
    let user: UserId
    let pack: UserId?
    let type: String
    let data: [String: String]
}

struct PostBody: Codable {
    let data: PostRequest
}

struct PostResponse: Codable {
    let data: PostEntry
}

struct PostListResponse: Codable {
    let data: [PostEntry]
}

struct PostEntry: Codable {
    let id: String
    let user: UserId
    let pack: UserId
    let type: String
    let data: [String: AnyCodable]
    let createdAt: String
    let image: [MediaData]?
}

struct CheerRequest: Codable {
    let sender: UserId
    let receiver: UserId
    let message: String
    let workoutId: String?
    let type: String?       // "text", "emoji", "sound"
    let isLive: Bool?       // true/false
}
struct CheerBody: Codable {
    let data: CheerRequest
}

struct CheerResponse: Codable {
    let data: CheerEntry
}

struct CheerListResponse: Codable {
    let data: [CheerEntry]
}

struct CheerEntry: Codable, Identifiable {
    let id: String
    let sender: UserId
    let receiver: UserId
    let message: String
    let createdAt: String
    let workoutId: String?
    let type: String?
    let isLive: Bool?
}


struct ChallengeRequest: Codable {
    let goal: Int
    let type: String
    let challenge_status: String?
    let winner: String?
    let challenger_user: UserId?
    let challengee_user: UserId?
    let challenger_pack: PackId?
    let challengee_pack: PackId?
    let participants: [UserId]?
    let startDate: String?
    let endDate: String?
    let metric: String?
}


struct ChallengeBody: Codable {
    let data: ChallengeRequest
}

struct ChallengeResponse: Codable {
    let data: ChallengeEntry
}

struct ChallengeListResponse: Codable {
    let data: [ChallengeEntry]
}

struct ChallengeEntry: Codable, Identifiable {
    let id: Int
    let documentId: String
    let goal: Int
    let type: String
    let challengeStatus: String?
    let winner: String?
    let challengerUser: UserId?
    let challengeeUser: UserId?
    let challengerPack: PackId?
    let challengeePack: PackId?
    let participants: [UserId]?
    let startDate: String?
    let endDate: String?
    let metric: String?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case goal
        case type
        case challengeStatus = "challenge_status"
        case winner
        case challengerUser = "challenger_user"
        case challengeeUser = "challengee_user"
        case challengerPack = "challenger_pack"
        case challengeePack = "challengee_pack"
        case participants
        case startDate
        case endDate
        case metric
    }
}
struct FriendRequest: Codable {
    let sender: UserId
    let receiver: UserId?
    let friendEmail: String
    let friendsStatus: String
    let inviteToken: String
    let senderName: String?
    let receiverName: String?

    enum CodingKeys: String, CodingKey {
        case sender
        case receiver
        case friendEmail
        case friendsStatus = "friends_status"
        case inviteToken
        case senderName
        case receiverName
    }
}
struct FriendBody: Codable {
    let data: FriendRequest
}

struct FriendResponse: Codable {
    let data: FriendEntry
}

struct FriendListResponse: Codable {
    let data: [FriendEntry]
}

struct FriendEntry: Codable {
    let id: Int
    let friendEmail: String
    let friendsStatus: String
    let inviteToken: String
    let createdAt: String
    let sender: FriendSender?
    let receiver: FriendReceiver?
    let senderName: String?
    let receiverName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case friendEmail
        case friendsStatus = "friends_status"
        case inviteToken
        case createdAt
        case sender
        case receiver
        case senderName
        case receiverName
    }
}

struct FriendSender: Codable {
    let data: UserId?
}

struct FriendReceiver: Codable {
    let data: UserId?
}

struct CommentRequest: Codable {
    let id: String
    let post: UserId
    let user: UserId
    let text: String
    let createdAt: String
}

struct CommentListResponse: Codable {
    let data: [CommentRequest]
}

struct StravaAuthResponse: Codable {
    let redirectUrl: String
}

struct StravaTokenRequest: Codable {
    let code: String
}

struct StravaTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
    let athlete: Athlete

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case athlete
    }
}

struct StravaCallbackRequest: Codable {
    let code: String
    let state: String
}

struct StravaCallbackResponse: Codable {
    let status: String
    let message: String?
}

struct DesiMessageResponse: Codable {
    let data: [DesiMessage]
    let meta: Meta
}

struct DesiMessage: Codable {
    let id: Int
    let documentId: String
    let title: String?
    let yesterdayLine: String
    let todayLine: String
    let badge: String?
    let languageStyle: String?
    let isPremium: Bool?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case title
        case yesterdayLine = "yesterday_line"
        case todayLine = "today_line"
        case badge
        case languageStyle = "language_style"
        case isPremium = "is_premium"
        case createdAt
        case updatedAt
        case publishedAt
    }
}

struct Meta: Codable {
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let pageSize: Int
    let pageCount: Int
    let total: Int
}

struct BadgeListResponse: Codable {
    let data: [BadgeEntry]
}

struct BadgeEntry: Codable {
    let id: Int
    let documentId: String
    let name: String
    let description: String
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let icon: Media?
}

struct Media: Codable {
    let id: Int
    let documentId: String
    let name: String
    let alternativeText: String?
    let caption: String?
    let width: Int
    let height: Int
    let formats: MediaFormats?
    let hash: String
    let ext: String
    let mime: String
    let size: Float
    let url: String
    let previewUrl: String?
    let provider: String
    let providerMetadata: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case name
        case alternativeText
        case caption
        case width
        case height
        case formats
        case hash
        case ext
        case mime
        case size
        case url
        case previewUrl
        case provider
        case providerMetadata = "provider_metadata"
        case createdAt
        case updatedAt
    }
}

struct MediaFormats: Codable {
    let large: MediaFormat?
    let medium: MediaFormat?
    let small: MediaFormat?
    let thumbnail: MediaFormat?
}

struct MediaFormat: Codable {
    let ext: String
    let url: String
    let hash: String
    let mime: String
    let name: String
    let path: String?
    let size: Float
    let width: Int
    let height: Int
    let sizeInBytes: Int
}

struct MediaData: Codable, Hashable {
    let id: Int
    let attributes: MediaAttributes
    let url: String
}

struct MediaAttributes: Codable, Hashable {
    let url: String
}

struct ExerciseListResponse: Codable {
    let data: [ExerciseEntry]
}

struct UserId: Codable, Hashable {
    let id: String?
}

struct StepSessionRequest: Codable {
    let startTime: String
    let endTime: String
    let steps: Int
    let caloriesBurned: Float
    let distance: Float
    let heartRateAvg: Int
    let source: String
    let tag: String?
    let usersPermissionsUser: UserId

    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
        case steps
        case caloriesBurned
        case distance
        case heartRateAvg
        case source
        case tag
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct StepSessionBody: Codable {
    let data: StepSessionRequest
}

struct StepSessionEntry: Codable {
    let id: Int
    let documentId: String
    let startTime: String
    let endTime: String
    let steps: Int
    let caloriesBurned: Float
    let distance: Float
    let heartRateAvg: Int
    let source: String
    let tag: String?
    let createdAt: String?
    let updatedAt: String?
    let publishedAt: String?
    let usersPermissionsUser: UserProfileResponse?

    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case startTime
        case endTime
        case steps
        case caloriesBurned
        case distance
        case heartRateAvg
        case source
        case tag
        case createdAt
        case updatedAt
        case publishedAt
        case usersPermissionsUser = "users_permissions_user"
    }
}

struct StepSessionResponse: Codable {
    let data: StepSessionEntry
}

struct StepSessionListResponse: Codable {
    let data: [StepSessionEntry]
}

// MARK: - Join Request Models
struct PackJoinRequest: Codable {
    let packId: Int
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case packId = "pack_id"
        case userId = "user_id"
    }
}

struct ChallengeJoinRequest: Codable {
    let challengeId: Int
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case userId = "user_id"
    }
}

// AnyCodable for flexible JSON parsing
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported JSON type"))
        }
    }
    
    
}
