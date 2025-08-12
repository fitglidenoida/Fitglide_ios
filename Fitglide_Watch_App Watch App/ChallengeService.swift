//
//  ChallengeService.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 11/08/25.
//

import Foundation

class ChallengeService {
    private let baseURL = "https://admin.fitglide.in/api"
    
    // MARK: - Challenge Data Models
    struct StrapiChallenge: Codable {
        let id: Int
        let documentId: String?
        let type: String?
        let goal: Int
        let challenge_status: String?
        let createdAt: String
        let updatedAt: String
        let publishedAt: String
        let winner: String?
        let startDate: String?
        let endDate: String?
        let metric: String?
        let title: String?
        let description: String?
        let level: String?
        let isPublic: Bool?
        let tags: [String]?
        let isRecommended: Bool?
        let maxParticipants: Int?
        let icon: String?
    }
    
    struct ChallengeResponse: Codable {
        let data: [StrapiChallenge]
        let meta: Meta
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
    
    struct UserChallengeProgress: Codable {
        let id: Int
        let attributes: ProgressAttributes
    }
    
    struct ProgressAttributes: Codable {
        let userId: String
        let challengeId: String
        let currentValue: Double
        let isCompleted: Bool
        let completedAt: String?
        let createdAt: String
        let updatedAt: String
    }
    
    struct ProgressResponse: Codable {
        let data: [UserChallengeProgress]
        let meta: Meta
    }
    
    // MARK: - API Methods
    func fetchActiveChallenges() async throws -> [StrapiChallenge] {
        // Try different filter approaches since 'isActive' might not exist
        let urlString = "\(baseURL)/challenges?populate=*&sort[0]=createdAt:desc"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: Add Bearer token when authentication is implemented
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Print response for debugging
        print("📡 Challenges API Response: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let challengeResponse = try JSONDecoder().decode(ChallengeResponse.self, from: data)
        return challengeResponse.data
    }
    
    func fetchUserChallengeProgress(userId: String) async throws -> [UserChallengeProgress] {
        guard let url = URL(string: "\(baseURL)/user-challenge-progress?filters[userId][$eq]=\(userId)&populate=*") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let progressResponse = try JSONDecoder().decode(ProgressResponse.self, from: data)
        return progressResponse.data
    }
    
    func updateChallengeProgress(userId: String, challengeId: String, currentValue: Double, isCompleted: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/user-challenge-progress") else {
            throw URLError(.badURL)
        }
        
        let progressData: [String: Any] = [
            "data": [
                "userId": userId,
                "challengeId": challengeId,
                "currentValue": currentValue,
                "isCompleted": isCompleted,
                "completedAt": isCompleted ? ISO8601DateFormatter().string(from: Date()) : nil
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func createChallengeProgress(userId: String, challengeId: String, currentValue: Double) async throws {
        guard let url = URL(string: "\(baseURL)/user-challenge-progress") else {
            throw URLError(.badURL)
        }
        
        let progressData: [String: Any] = [
            "data": [
                "userId": userId,
                "challengeId": challengeId,
                "currentValue": currentValue,
                "isCompleted": false
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: progressData)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - API Health Check
    func testAPIConnectivity() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            print("🏥 API Health Check: \(httpResponse.statusCode)")
            return httpResponse.statusCode == 200
        } catch {
            print("❌ API Health Check Failed: \(error)")
            return false
        }
    }
}
