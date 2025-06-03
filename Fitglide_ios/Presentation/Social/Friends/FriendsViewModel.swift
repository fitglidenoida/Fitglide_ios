//
//  FriendsViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

class FriendsViewModel: ObservableObject {
    @Published var sentRequests: [FriendEntry] = []
    @Published var receivedRequests: [FriendEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var emailToInvite: String = ""
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    
    
    @MainActor
    func loadFriends() async {
        guard let userId = authRepository.authState.userId else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let filters: [String: String] = [:] // No filters for now (load all)
            let response = try await strapiRepository.getFriends(filters: filters)
            self.sentRequests = response.data.filter { $0.sender?.data?.id == userId }
            self.receivedRequests = response.data.filter { $0.receiver?.data?.id == userId }
        } catch {
            self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func sendFriendRequest() async {
        guard let userId = authRepository.authState.userId else { return }
        guard !emailToInvite.isEmpty else {
            errorMessage = "Please enter an email"
            return
        }
        
        let senderName = authRepository.authState.firstName ?? "You"
        _ = authRepository.authState.jwt ?? ""
        
        let request = FriendRequest(
            sender: UserId(id: userId),
            receiver: nil,
            friendEmail: emailToInvite,
            friendsStatus: "Pending",
            inviteToken: UUID().uuidString,
            senderName: senderName,
            receiverName: nil
        )
        
        do {
            _ = try await strapiRepository.postFriend(request: request)
            emailToInvite = ""
            await loadFriends()
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func respondToFriendRequest(id: Int, accept: Bool) async {
        guard let index = receivedRequests.firstIndex(where: { $0.id == id }) else { return }
        
        let updated = receivedRequests[index]
        let newStatus = accept ? "Accepted" : "Rejected"
        
        let updatedRequest = FriendRequest(
            sender: updated.sender?.data ?? UserId(id: nil),
            receiver: updated.receiver?.data,
            friendEmail: updated.friendEmail,
            friendsStatus: newStatus,
            inviteToken: updated.inviteToken,
            senderName: updated.senderName,
            receiverName: updated.receiverName
        )
        
        do {
            _ = try await strapiRepository.updateFriend(id: String(id), request: updatedRequest)
            await loadFriends()
        } catch {
            errorMessage = "Failed to update request"
        }
    }
}

