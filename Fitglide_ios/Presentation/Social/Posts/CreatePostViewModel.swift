//
//  CreatePostViewModel.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI
import PhotosUI

class CreatePostViewModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var content: String = ""
    @Published var type: String = "manual" // "manual", "streak", "live"
    @Published var selectedPackId: String? = nil
    @Published var imageItem: PhotosPickerItem? = nil
    @Published var imageData: Data? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var postSuccess = false

    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository

    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }

    @MainActor
    func createPost() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let userId = authRepository.authState.userId else {
            errorMessage = "User not authenticated"
            return
        }

        // Upload image if present
        var imageId: String? = nil
        if let imageData = imageData {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try imageData.write(to: tempURL)

                // ⚠️ Replace this with your actual uploadFile function
                let uploadResult = try await strapiRepository.uploadFile(file: tempURL)
                imageId = uploadResult.first.map { String($0.id) }
            } catch {
                errorMessage = "Image upload failed: \(error.localizedDescription)"
                return
            }
        }

        // Construct data
        let postData: [String: String] = [
            "content": content,
            "mediaId": imageId ?? ""
        ]

        let request = PostRequest(
            user: UserId(id: userId),
            pack: selectedPackId != nil ? UserId(id: selectedPackId!) : nil,
            type: type,
            data: postData
        )

        do {
            _ = try await strapiRepository.postPost(request: request)
            postSuccess = true
        } catch {
            errorMessage = "Post creation failed: \(error.localizedDescription)"
        }
    }
}
