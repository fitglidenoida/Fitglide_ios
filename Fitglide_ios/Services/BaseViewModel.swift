//
//  BaseViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 22/07/25.
//

import Foundation
import SwiftUI
import OSLog
import Combine

// MARK: - BaseViewModel Protocol
@MainActor
protocol BaseViewModelProtocol: ObservableObject {
    var uiMessage: String? { get set }
    var isLoading: Bool { get set }
}

// MARK: - BaseViewModel
@MainActor
class BaseViewModel: BaseViewModelProtocol {
    @Published var uiMessage: String? = nil
    @Published var isLoading: Bool = false
    
    // Common dependencies
    let strapiRepository: StrapiRepository
    let authRepository: AuthRepository
    let healthService: HealthService
    let logger: Logger
    
    // Common formatters
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    // MARK: - Initialization
    init(
        strapiRepository: StrapiRepository,
        authRepository: AuthRepository,
        healthService: HealthService,
        loggerCategory: String
    ) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
        self.healthService = healthService
        self.logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: loggerCategory)
    }
    
    // MARK: - Common Authentication Checks
    func validateAuth() -> Bool {
        guard let userId = authRepository.authState.userId else {
            let errorMessage = "Missing user ID"
            logger.error("\(errorMessage)")
            uiMessage = errorMessage
            return false
        }
        
        guard authRepository.authState.jwt != nil else {
            let errorMessage = "Missing JWT token"
            logger.error("\(errorMessage)")
            uiMessage = errorMessage
            return false
        }
        
        logger.debug("Auth validated for user: \(userId)")
        return true
    }
    
    // MARK: - Common Error Handling
    func handleError(_ error: Error, context: String) {
        let errorMessage = "\(context): \(error.localizedDescription)"
        logger.error("\(errorMessage)")
        uiMessage = errorMessage
    }
    
    func handleDecodingError(_ error: DecodingError, context: String) {
        switch error {
        case .dataCorrupted(let context):
            logger.error("Data corrupted: \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            logger.error("Key not found: \(key.stringValue), context: \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            logger.error("Type mismatch: expected \(type), context: \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            logger.error("Value not found: expected \(type), context: \(context.debugDescription)")
        @unknown default:
            logger.error("Unknown decoding error: \(error)")
        }
        
        let errorMessage = "\(context): Data parsing error"
        uiMessage = errorMessage
    }
    
    // MARK: - Common API Retry Logic
    func retryOperation<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                logger.error("Attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NSError(domain: "BaseViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"])
    }
    
    // MARK: - Common Loading State Management
    func withLoading<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        return try await operation()
    }
    
    // MARK: - Common Success Message
    func showSuccess(_ message: String) {
        uiMessage = message
        logger.debug("Success: \(message)")
    }
    
    // MARK: - Common Date Utilities
    func formatDate(_ date: Date, format: String = "MMM d, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    func endOfDay(_ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(date)) ?? date
    }
    
    // MARK: - Common Validation
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validateRequired(_ value: String?, fieldName: String) -> Bool {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            uiMessage = "\(fieldName) is required"
            return false
        }
        return true
    }
    
    // MARK: - Common Data Persistence
    func saveToUserDefaults<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            logger.error("Failed to save to UserDefaults: \(error.localizedDescription)")
        }
    }
    
    func loadFromUserDefaults<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            logger.error("Failed to load from UserDefaults: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Common Health Data Validation
    func validateHealthData(_ value: Double, min: Double, max: Double, fieldName: String) -> Bool {
        guard value >= min && value <= max else {
            uiMessage = "\(fieldName) must be between \(min) and \(max)"
            return false
        }
        return true
    }
    
    // MARK: - Common Network Status
    func isNetworkAvailable() -> Bool {
        // Basic network check - can be enhanced with Reachability
        return true
    }
}

// MARK: - ViewModel Factory
@MainActor
class ViewModelFactory {
    static func createHomeViewModel() -> HomeViewModel {
        let authRepo = AuthRepository()
        let strapiRepo = StrapiRepository(authRepository: authRepo)
        let healthService = HealthService()
        
        return HomeViewModel(
            strapiRepository: strapiRepo,
            authRepository: authRepo,
            healthService: healthService
        )
    }
    
    static func createMealsViewModel() -> MealsViewModel {
        let authRepo = AuthRepository()
        let strapiRepo = StrapiRepository(authRepository: authRepo)
        
        return MealsViewModel(
            strapi: strapiRepo,
            auth: authRepo
        )
    }
}

// MARK: - Common Extensions
extension String {
    var floatValue: Float? {
        return Float(self)
    }
    
    var intValue: Int? {
        return Int(self)
    }
    
    var doubleValue: Double? {
        return Double(self)
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

extension Float {
    func rounded(to places: Int) -> Float {
        let multiplier = pow(10.0, Float(places))
        return (self * multiplier).rounded() / multiplier
    }
} 