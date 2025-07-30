//
//  PackInvite.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 27/07/25.
//

import Foundation

struct PackInvite: Codable, Identifiable {
    let id: Int
    let packId: Int
    let packName: String
    let inviterId: Int
    let inviterName: String
    let inviteeId: Int
    let status: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case packId = "pack_id"
        case packName = "pack_name"
        case inviterId = "inviter_id"
        case inviterName = "inviter_name"
        case inviteeId = "invitee_id"
        case status
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct PackInviteResponse: Codable {
    let data: [PackInvite]
    let meta: Meta?
} 