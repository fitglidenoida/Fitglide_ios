//
//  FriendSelectorView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 20/07/25.
//

import SwiftUI

struct FriendSelectorView: View {
    @ObservedObject var viewModel: FriendSelectorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    emptySearchView
                } else if viewModel.friends.isEmpty {
                    emptyStateView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Select Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.confirmSelection()
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                    .disabled(viewModel.selectedFriends.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel.loadFriends()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search friends...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: viewModel.searchText) { _, _ in
                    viewModel.searchFriends()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    viewModel.searchFriends()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(colors.surface)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading friends...")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No friends found")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.primary)
            
            Text("Try searching with a different name")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.primary)
            
            Text("Add friends to get started with social features")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Friends") {
                viewModel.addFriends()
            }
            .font(.custom("Poppins-Medium", size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(colors.primary)
            .cornerRadius(8)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var friendsList: some View {
        List {
            ForEach(viewModel.displayFriends) { friend in
                FriendRowView(
                    friend: friend,
                    isSelected: viewModel.selectedFriends.contains(friend.id),
                    onToggle: {
                        viewModel.toggleFriendSelection(friend.id)
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: SocialData.Friend
    let isSelected: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if let avatarUrl = friend.avatarUrl, !avatarUrl.isEmpty {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(friend.name.prefix(1).uppercased())
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(colors.primary)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Text(friend.name.prefix(1).uppercased())
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(colors.primary)
                }
                
                // Online indicator
                if friend.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 18, y: -18)
                }
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.primary)
                
                if let lastActivity = friend.lastActivity {
                    Text("Last active \(formatLastActivity(lastActivity))")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Selection button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? colors.primary : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(colors.primary)
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    private func formatLastActivity(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Friend Selector View Model
@MainActor
class FriendSelectorViewModel: ObservableObject {
    @Published var friends: [SocialData.Friend] = []
    @Published var selectedFriends: Set<String> = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var searchResults: [SocialData.Friend] = []
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    var displayFriends: [SocialData.Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return searchResults
        }
    }
    
    init(strapiRepository: StrapiRepository, authRepository: AuthRepository) {
        self.strapiRepository = strapiRepository
        self.authRepository = authRepository
    }
    
    func loadFriends() {
        Task {
            isLoading = true
            
            do {
                // Load friends from API
                let friendsResponse = try await strapiRepository.getFriends(filters: [:])
                await MainActor.run {
                    self.friends = friendsResponse.data.map { friendData in
                        SocialData.Friend(
                            id: String(friendData.id),
                            name: friendData.senderName ?? friendData.receiverName ?? "Unknown",
                            avatarUrl: nil, // FriendEntry doesn't have avatarUrl
                            isOnline: false, // FriendEntry doesn't have isOnline
                            lastActivity: nil // FriendEntry doesn't have lastActivity
                        )
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Handle error
                }
            }
        }
    }
    
    func searchFriends() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        searchResults = friends.filter { friend in
            friend.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func toggleFriendSelection(_ friendId: String) {
        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }
    }
    
    func confirmSelection() {
        // Handle the selected friends
        print("Selected friends: \(selectedFriends)")
    }
    
    func addFriends() {
        // Navigate to add friends screen
        print("Navigate to add friends")
    }
}



// MARK: - Preview
struct FriendSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let authRepo = AuthRepository()
        let strapiRepo = StrapiRepository(authRepository: authRepo)
        let viewModel = FriendSelectorViewModel(strapiRepository: strapiRepo, authRepository: authRepo)
        
        FriendSelectorView(viewModel: viewModel)
    }
} 