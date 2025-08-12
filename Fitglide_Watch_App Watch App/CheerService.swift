//
//  CheerService.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 11/08/25.
//

import Foundation

class CheerService {
    private let baseURL = "https://admin.fitglide.in/api"
    
    // MARK: - Cheer Data Models
    struct StrapiCheer: Codable {
        let id: String
        let sender: UserId
        let receiver: UserId
        let message: String
        let createdAt: String
        let workoutId: String?
        let type: String?
        let isLive: Bool?
    }
    
    struct UserId: Codable {
        let id: String
        let username: String?
        let email: String?
        let firstName: String?
        let lastName: String?
        let profilePicture: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case profilePicture = "profile_picture"
        }
    }
    
    struct CheerListResponse: Codable {
        let data: [StrapiCheer]
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
    
    struct CheerRequest: Codable {
        let sender: String
        let receiver: String
        let message: String
        let workoutId: String?
        let type: String?
        let isLive: Bool?
    }
    
    struct CheerResponse: Codable {
        let data: StrapiCheer
    }
    
    struct LiveCheerRequest: Codable {
        let sender: String
        let receiver: String
        let message: String
        let workoutType: String
        let duration: String
        let startTime: Double
        let isLive: Bool
    }
    
    // MARK: - API Methods
    func fetchCheers(userId: String) async throws -> [StrapiCheer] {
        // Try without user filter first, then filter locally
        let urlString = "\(baseURL)/cheers?populate=*&sort[0]=createdAt:desc"
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
        print("📡 Cheers API Response: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response body: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let cheerResponse = try JSONDecoder().decode(CheerListResponse.self, from: data)
        return cheerResponse.data
    }
    
    func sendCheer(senderId: String, receiverId: String, message: String, workoutId: String? = nil, type: String? = nil, isLive: Bool = false) async throws -> StrapiCheer {
        guard let url = URL(string: "\(baseURL)/cheers") else {
            throw URLError(.badURL)
        }
        
        // Removed unused cheerData variable
        
        let requestBody: [String: Any] = [
            "data": [
                "sender": senderId,
                "receiver": receiverId,
                "message": message,
                "workoutId": workoutId as Any,
                "type": type as Any,
                "isLive": isLive
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        let cheerResponse = try JSONDecoder().decode(CheerResponse.self, from: data)
        return cheerResponse.data
    }
    
    func sendLiveCheer(senderId: String, receiverId: String, message: String, workoutType: String, duration: String, startTime: Double) async throws -> StrapiCheer {
        return try await sendCheer(
            senderId: senderId,
            receiverId: receiverId,
            message: message,
            type: "live_workout",
            isLive: true
        )
    }
    
    func sendLiveCheerToMultipleUsers(senderId: String, receiverIds: [String], message: String, workoutType: String, duration: String, startTime: Double) async throws {
        // Send cheers to multiple users concurrently
        await withTaskGroup(of: Void.self) { group in
            for receiverId in receiverIds {
                group.addTask {
                    do {
                        _ = try await self.sendLiveCheer(
                            senderId: senderId,
                            receiverId: receiverId,
                            message: message,
                            workoutType: workoutType,
                            duration: duration,
                            startTime: startTime
                        )
                    } catch {
                        print("❌ Failed to send live cheer to \(receiverId): \(error)")
                    }
                }
            }
        }
    }
    
    func fetchLiveCheers(userId: String) async throws -> [StrapiCheer] {
        guard let url = URL(string: "\(baseURL)/cheers?filters[receiver][id][$eq]=\(userId)&filters[isLive][$eq]=true&populate=*&sort[0]=createdAt:desc") else {
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
        
        let cheerResponse = try JSONDecoder().decode(CheerListResponse.self, from: data)
        return cheerResponse.data
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
