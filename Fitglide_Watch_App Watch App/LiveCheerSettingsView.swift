//
//  LiveCheerSettingsView.swift
//  Fitglide_Watch_App
//
//  Created by Sandip Tiwari on 27/07/25.
//

import SwiftUI

struct LiveCheerSettingsView: View {
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingFriendPicker = false
    @State private var showingPackPicker = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Live Cheer Settings") {
                    Toggle("Enable Live Cheers", isOn: $liveCheerManager.isLiveCheerEnabled)
                        .onChange(of: liveCheerManager.isLiveCheerEnabled) { _, newValue in
                            if newValue {
                                liveCheerManager.enableLiveCheer()
                            } else {
                                liveCheerManager.disableLiveCheer()
                            }
                        }
                    
                    if liveCheerManager.isLiveCheerEnabled {
                        HStack {
                            Text("Cheers Received")
                            Spacer()
                            if liveCheerManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("\(liveCheerManager.cheerCount)")
                                    .foregroundColor(.orange)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await liveCheerManager.loadCheersFromStrapi()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                
                // Error State
                if let errorMessage = liveCheerManager.errorMessage {
                    Section("Error") {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if liveCheerManager.isLiveCheerEnabled {
                    Section("Friends") {
                        if liveCheerManager.selectedFriends.isEmpty {
                            Text("No friends selected")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(liveCheerManager.selectedFriends, id: \.self) { friendId in
                                HStack {
                                    Text("Friend \(friendId)")
                                    Spacer()
                                    Button("Remove") {
                                        liveCheerManager.removeFriend(friendId)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                            }
                        }
                        
                        Button("Add Friends") {
                            showingFriendPicker = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    
                    Section("Packs") {
                        if liveCheerManager.selectedPacks.isEmpty {
                            Text("No packs selected")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(liveCheerManager.selectedPacks, id: \.self) { packId in
                                HStack {
                                    Text("Pack \(packId)")
                                    Spacer()
                                    Button("Remove") {
                                        liveCheerManager.removePack(packId)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                }
                            }
                        }
                        
                        Button("Add Packs") {
                            showingPackPicker = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }
                
                Section("Info") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Cheers will notify your selected friends and packs when you start a workout.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("They can send you cheers in real-time while you're working out!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Live Cheer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
        .sheet(isPresented: $showingFriendPicker) {
            FriendPickerView()
        }
        .sheet(isPresented: $showingPackPicker) {
            PackPickerView()
        }
    }
}

struct FriendPickerView: View {
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @Environment(\.dismiss) private var dismiss
    
    // Mock friends data - in real app, this would come from the iPhone app
    private let mockFriends = [
        ("friend1", "John Doe"),
        ("friend2", "Jane Smith"),
        ("friend3", "Mike Johnson")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mockFriends, id: \.0) { friend in
                    Button(action: {
                        liveCheerManager.addFriend(friend.0)
                        dismiss()
                    }) {
                        HStack {
                            Text(friend.1)
                            Spacer()
                            if liveCheerManager.selectedFriends.contains(friend.0) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Friends")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

struct PackPickerView: View {
    @EnvironmentObject var liveCheerManager: LiveCheerManager
    @Environment(\.dismiss) private var dismiss
    
    // Mock packs data - in real app, this would come from the iPhone app
    private let mockPacks = [
        ("pack1", "Morning Runners"),
        ("pack2", "Gym Buddies"),
        ("pack3", "Yoga Enthusiasts")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mockPacks, id: \.0) { pack in
                    Button(action: {
                        liveCheerManager.addPack(pack.0)
                        dismiss()
                    }) {
                        HStack {
                            Text(pack.1)
                            Spacer()
                            if liveCheerManager.selectedPacks.contains(pack.0) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Packs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}

#Preview {
    LiveCheerSettingsView()
        .environmentObject(LiveCheerManager())
} 