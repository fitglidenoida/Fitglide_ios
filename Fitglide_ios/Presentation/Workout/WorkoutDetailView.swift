//
//  WorkoutDetailView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 12/07/25.
//

import Foundation
import SwiftUI
import MapKit

enum ShareOption: String, CaseIterable {
    case external = "External"
    case friends = "Friends"
    case packs = "Packs"
    case challenge = "Create Challenge"
    
    var icon: String {
        switch self {
        case .external: return "square.and.arrow.up"
        case .friends: return "person.2.fill"
        case .packs: return "person.3.fill"
        case .challenge: return "trophy.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .external: return .blue
        case .friends: return .green
        case .packs: return .orange
        case .challenge: return .purple
        }
    }
}

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let workout: WorkoutLogEntry
    let strapiRepository: StrapiRepository
    let authRepository: AuthRepository
    let healthService: HealthService
    
    @State private var workoutLog: WorkoutLogEntry? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var animateContent = false
    @State private var showWellnessQuote = false
    @State private var showShareMenu = false
    @State private var selectedShareOption: ShareOption = .external
    @State private var showFriendsList = false
    @State private var showPacksList = false
    @State private var showCreateChallenge = false
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        colors.background,
                        colors.surface.opacity(0.3),
                        colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
            if let log = workoutLog {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Modern Header Section
                            modernHeaderSection(log: log)
                            
                            // Indian Wellness Quote
                            if showWellnessQuote {
                                indianWellnessQuoteCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Workout Stats Overview
                            workoutStatsOverview(log: log)
                            
                            // Map Section (if available)
                    if let route = log.route, !route.isEmpty {
                                mapSection(route: route)
                            }
                            
                            // Detailed Metrics
                            detailedMetricsSection(log: log)
                            
                            // Heart Rate Zones (if available)
                            if log.heartRateAverage ?? 0 > 0 {
                                heartRateZonesSection(log: log)
                            }
                            
                            // Achievements Section
                            achievementsSection(log: log)
                            
                            // Quick Actions
                            quickActionsSection(log: log)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .foregroundColor(colors.primary)
                        
                        Text("Loading workout details...")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
            }
                         .overlay(
                 // Custom Share Menu
                 Group {
                     if showShareMenu {
                         customShareMenu
                     }
                 }
             )
             .sheet(isPresented: $showFriendsList) {
                 FriendsShareView(workout: workoutLog ?? workout)
             }
             .sheet(isPresented: $showPacksList) {
                 PacksShareView(workout: workoutLog ?? workout)
             }
             .sheet(isPresented: $showCreateChallenge) {
                 WorkoutChallengeView(workout: workoutLog ?? workout)
             }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateContent = true
                }
                
                // Show wellness quote after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showWellnessQuote = true
                    }
                }
                
                loadWorkoutDetails()
            }
        }
    }
    
    // MARK: - Modern Header Section
    func modernHeaderSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.type ?? "Workout")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(colors.onSurface)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text(formatDuration(log.totalTime ?? 0))
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                        .offset(x: animateContent ? 0 : -20)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Workout type icon
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                    
                    Image(systemName: workoutTypeIcon(log.type ?? ""))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.primary)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            colors.background
                .shadow(color: colors.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Wellness Quote Card
    var indianWellnessQuoteCard: some View {
        VStack(spacing: 12) {
            Text("""
                "Every step you take is a step towards better health."
                """)
            .font(FitGlideTheme.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(colors.onSurface)
            .multilineTextAlignment(.center)
            
            Text("Ancient Indian Wisdom")
                .font(FitGlideTheme.caption)
                .foregroundColor(colors.onSurfaceVariant)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.1), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Workout Stats Overview
    func workoutStatsOverview(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workout Summary")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ModernWorkoutStatCard(
                    title: "Calories",
                    value: "\(Int(log.calories ?? 0))",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.1
                )
                
                ModernWorkoutStatCard(
                    title: "Distance",
                    value: String(format: "%.2f", log.distance ?? 0),
                    unit: "km",
                    icon: "figure.walk",
                    color: .green,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.2
                )
                
                ModernWorkoutStatCard(
                    title: "Heart Rate",
                    value: "\(log.heartRateAverage ?? 0)",
                    unit: "bpm",
                    icon: "heart.fill",
                    color: .red,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.3
                )
                
                ModernWorkoutStatCard(
                    title: "Pace",
                    value: calculatePace(log),
                    unit: "/km",
                    icon: "speedometer",
                    color: .blue,
                    theme: colors,
                    animateContent: $animateContent,
                    delay: 0.4
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Map Section
    func mapSection(route: [[String: Float]]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Route")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            // Placeholder for MapView - you'll need to implement this
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surfaceVariant)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundColor(colors.onSurfaceVariant)
                        Text("Route Map (\(route.count) points)")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                )
                .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    // MARK: - Detailed Metrics Section
    func detailedMetricsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
                                        HStack {
                Text("Detailed Metrics")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernDetailRow(
                    title: "Max Heart Rate",
                    value: "\(log.heartRateMaximum ?? 0) bpm",
                    icon: "heart.circle.fill",
                    color: .red,
                    theme: colors
                )
                
                ModernDetailRow(
                    title: "Min Heart Rate",
                    value: "\(log.heartRateMinimum ?? 0) bpm",
                    icon: "heart.circle",
                    color: .blue,
                    theme: colors
                )
                
                if let notes = log.notes, !notes.isEmpty {
                    ModernDetailRow(
                        title: "Notes",
                        value: notes,
                        icon: "note.text",
                        color: .purple,
                        theme: colors
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Heart Rate Zones Section
    func heartRateZonesSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Heart Rate Zones")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ModernZoneCard(
                    title: "Low Zone",
                    subtitle: "50-70%",
                    value: heartRateZone(log, low: 0.5, high: 0.7),
                    color: .green,
                    theme: colors
                )
                
                ModernZoneCard(
                    title: "Moderate Zone",
                    subtitle: "70-85%",
                    value: heartRateZone(log, low: 0.7, high: 0.85),
                    color: .orange,
                    theme: colors
                )
                
                ModernZoneCard(
                    title: "High Zone",
                    subtitle: "85-100%",
                    value: heartRateZone(log, low: 0.85, high: 1.0),
                    color: .red,
                    theme: colors
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Achievements Section
    func achievementsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            let achievements = getAchievements(log)
            if achievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 40))
                        .foregroundColor(colors.onSurfaceVariant.opacity(0.5))
                    
                    Text("No achievements yet")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("Keep pushing yourself to unlock achievements!")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievements, id: \.self) { badge in
                            ModernAchievementCard(
                                title: badge,
                                icon: "rosette.fill",
                                color: .yellow,
                                theme: colors
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateContent)
    }
    
    // MARK: - Quick Actions
    func quickActionsSection(log: WorkoutLogEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ModernButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    style: .primary
                ) {
                    showShareMenu = true
                }
                
                ModernButton(
                    title: "Save",
                    icon: "bookmark",
                    style: .secondary
                ) {
                    // Save workout
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Custom Share Menu
    var customShareMenu: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showShareMenu = false
                    }
                }
            
            // Share menu card
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Share Workout")
                        .font(FitGlideTheme.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.onSurface)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showShareMenu = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colors.onSurfaceVariant)
                    }
                }
                
                // Share options grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(ShareOption.allCases, id: \.self) { option in
                        ShareOptionCard(
                            option: option,
                            action: {
                                handleShareOption(option, log: workoutLog ?? workout)
                            },
                            theme: colors
                        )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colors.surface)
                    .shadow(color: colors.onSurface.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showShareMenu)
    }
    
    // MARK: - Share Option Card
    struct ShareOptionCard: View {
        let option: ShareOption
        let action: () -> Void
        let theme: FitGlideTheme.Colors
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 12) {
                    Image(systemName: option.icon)
                        .font(.title2)
                        .foregroundColor(option.color)
                    
                    Text(option.rawValue)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.surfaceVariant)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(option.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Share Option Handler
    private func handleShareOption(_ option: ShareOption, log: WorkoutLogEntry) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showShareMenu = false
        }
        
        switch option {
        case .external:
            shareToExternal(log: log)
        case .friends:
            shareToFriends(log: log)
        case .packs:
            shareToPacks(log: log)
        case .challenge:
            createChallenge(log: log)
        }
    }
    
    // MARK: - Share Methods
    private func shareToExternal(log: WorkoutLogEntry) {
        let shareText = """
🏃 FitGlide Workout Summary 🏃
Type: \(log.type ?? "Workout")
Distance: \(String(format: "%.2f", log.distance ?? 0)) km
Calories: \(Int(log.calories ?? 0)) kcal
Duration: \(formatDuration(log.totalTime ?? 0))
Avg HR: \(log.heartRateAverage ?? 0) bpm
#FitGlide #Fitness #Workout
"""

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return
        }

        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }

        topController.present(activityVC, animated: true)
    }
    
         private func shareToFriends(log: WorkoutLogEntry) {
         showFriendsList = true
     }
     
     private func shareToPacks(log: WorkoutLogEntry) {
         showPacksList = true
     }
     
     private func createChallenge(log: WorkoutLogEntry) {
         showCreateChallenge = true
     }
    
    // MARK: - Helper Methods
    private func loadWorkoutDetails() {
        // Use the existing workout data
        workoutLog = workout
    }
    
    private func extractDateFromLogId(_ logId: String) -> Date? {
        let pattern = #"wearable_(\d{4}-\d{2}-\d{2})"#  // extract date portion
        if let match = logId.range(of: pattern, options: .regularExpression) {
            let dateString = String(logId[match]).replacingOccurrences(of: "wearable_", with: "")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "UTC")
            return formatter.date(from: dateString)
        }
        return nil
    }



    
    private func workoutTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        default: return "figure.run"
        }
    }
}

// MARK: - Friends Share View
struct FriendsShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let workout: WorkoutLogEntry
    
    @State private var friends: [FriendEntry] = []
    @State private var selectedFriends: Set<String> = []
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(workout: WorkoutLogEntry) {
        self.workout = workout
        self.strapiRepository = StrapiRepository(authRepository: AuthRepository())
        self.authRepository = AuthRepository()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading friends...")
                        .foregroundColor(colors.onSurface)
                } else if friends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(colors.onSurfaceVariant)
                        
                        Text("No Friends Found")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.onSurface)
                        
                        Text("Add friends to share your workouts with them")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Share with Friends")
                                .font(FitGlideTheme.titleLarge)
                                .fontWeight(.bold)
                                .foregroundColor(colors.onSurface)
                            
                            Text("Select friends to share your workout with")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Friends List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(friends, id: \.id) { friend in
                                    FriendRow(
                                        friend: friend,
                                        isSelected: selectedFriends.contains(String(friend.id)),
                                        onToggle: { isSelected in
                                            if isSelected {
                                                selectedFriends.insert(String(friend.id))
                                            } else {
                                                selectedFriends.remove(String(friend.id))
                                            }
                                        },
                                        theme: colors
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Share Button
                        if !selectedFriends.isEmpty {
                            VStack(spacing: 16) {
                                Text("\(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s") selected")
                                    .font(FitGlideTheme.bodyMedium)
                                    .foregroundColor(colors.onSurfaceVariant)
                                
                                ModernButton(
                                    title: "Share Workout",
                                    icon: "paperplane.fill",
                                    style: .primary
                                ) {
                                    shareWithSelectedFriends()
                                }
                            }
                            .padding(24)
                            .background(
                                Rectangle()
                                    .fill(colors.surface)
                                    .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: -4)
                            )
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
        .onAppear {
            loadFriends()
        }
        .alert("Share Result", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadFriends() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    alertMessage = "User not logged in"
                    showAlert = true
                    isLoading = false
                    return
                }
                
                let filters: [String: String] = [:] // Load all friends
                let response = try await strapiRepository.getFriends(filters: filters)
                
                // Filter to show only accepted friends for the current user
                let acceptedFriends = response.data.filter { friend in
                    // Show friends where current user is either sender or receiver and status is "Accepted"
                    let isSender = friend.sender?.data?.id == userId
                    let isReceiver = friend.receiver?.data?.id == userId
                    let isAccepted = friend.friendsStatus == "Accepted"
                    
                    return (isSender || isReceiver) && isAccepted
                }
                
                await MainActor.run {
                    self.friends = acceptedFriends
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to load friends: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func shareWithSelectedFriends() {
        // TODO: Implement actual sharing with friends
        alertMessage = "Workout shared with \(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")!"
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Packs Share View
struct PacksShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let workout: WorkoutLogEntry
    
    @State private var packs: [PackEntry] = []
    @State private var selectedPack: String? = nil
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(workout: WorkoutLogEntry) {
        self.workout = workout
        self.strapiRepository = StrapiRepository(authRepository: AuthRepository())
        self.authRepository = AuthRepository()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading packs...")
                        .foregroundColor(colors.onSurface)
                } else if packs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.slash")
                            .font(.system(size: 48))
                            .foregroundColor(colors.onSurfaceVariant)
                        
                        Text("No Packs Found")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.onSurface)
                        
                        Text("Join packs to share your workouts with them")
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(colors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Share with Pack")
                                .font(FitGlideTheme.titleLarge)
                                .fontWeight(.bold)
                                .foregroundColor(colors.onSurface)
                            
                            Text("Select a pack to share your workout with")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Packs List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(packs, id: \.id) { pack in
                                    PackRow(
                                        pack: pack,
                                        isSelected: selectedPack == String(pack.id),
                                        onSelect: { packId in
                                            selectedPack = packId
                                        },
                                        theme: colors
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                        
                        // Share Button
                        if selectedPack != nil {
                            VStack(spacing: 16) {
                                if let selectedPackId = selectedPack,
                                   let pack = packs.first(where: { String($0.id) == selectedPackId }) {
                                    Text("Selected: \(pack.name)")
                                        .font(FitGlideTheme.bodyMedium)
                                        .foregroundColor(colors.onSurfaceVariant)
                                }
                                
                                ModernButton(
                                    title: "Share with Pack",
                                    icon: "paperplane.fill",
                                    style: .primary
                                ) {
                                    shareWithSelectedPack()
                                }
                            }
                            .padding(24)
                            .background(
                                Rectangle()
                                    .fill(colors.surface)
                                    .shadow(color: colors.onSurface.opacity(0.1), radius: 8, x: 0, y: -4)
                            )
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
        .onAppear {
            loadPacks()
        }
        .alert("Share Result", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadPacks() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    alertMessage = "User not logged in"
                    showAlert = true
                    isLoading = false
                    return
                }
                
                let response = try await strapiRepository.getPacks(userId: userId)
                
                await MainActor.run {
                    self.packs = response.data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to load packs: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func shareWithSelectedPack() {
        // TODO: Implement actual sharing
        if let selectedPackId = selectedPack,
           let pack = packs.first(where: { String($0.id) == selectedPackId }) {
            alertMessage = "Workout shared with \(pack.name) pack!"
            showAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Workout Challenge View
struct WorkoutChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    let workout: WorkoutLogEntry
    
    @State private var challengeName = ""
    @State private var challengeDescription = ""
    @State private var selectedFriends: Set<String> = []
    @State private var selectedPacks: Set<String> = []
    @State private var duration = 7
    @State private var friends: [FriendEntry] = []
    @State private var packs: [PackEntry] = []
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let strapiRepository: StrapiRepository
    private let authRepository: AuthRepository
    
    private var colors: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    init(workout: WorkoutLogEntry) {
        self.workout = workout
        self.strapiRepository = StrapiRepository(authRepository: AuthRepository())
        self.authRepository = AuthRepository()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Create Challenge")
                                .font(FitGlideTheme.titleLarge)
                                .fontWeight(.bold)
                                .foregroundColor(colors.onSurface)
                            
                            Text("Create a challenge based on your workout")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(colors.onSurfaceVariant)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Challenge Details
                        VStack(spacing: 20) {
                            // Challenge Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Challenge Name")
                                    .font(FitGlideTheme.bodyMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(colors.onSurface)
                                
                                TextField("Enter challenge name", text: $challengeName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .background(colors.surface)
                            }
                            
                            // Challenge Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(FitGlideTheme.bodyMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(colors.onSurface)
                                
                                TextField("Enter challenge description", text: $challengeDescription, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...6)
                                    .background(colors.surface)
                            }
                            
                            // Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Duration (days)")
                                    .font(FitGlideTheme.bodyMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(colors.onSurface)
                                
                                Picker("Duration", selection: $duration) {
                                    Text("3 days").tag(3)
                                    Text("7 days").tag(7)
                                    Text("14 days").tag(14)
                                    Text("30 days").tag(30)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Invite Friends
                        if !friends.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Invite Friends")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colors.onSurface)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(friends, id: \.id) { friend in
                                        FriendRow(
                                            friend: friend,
                                            isSelected: selectedFriends.contains(String(friend.id)),
                                            onToggle: { isSelected in
                                                if isSelected {
                                                    selectedFriends.insert(String(friend.id))
                                                } else {
                                                    selectedFriends.remove(String(friend.id))
                                                }
                                            },
                                            theme: colors
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Invite Packs
                        if !packs.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Invite Packs")
                                    .font(FitGlideTheme.titleMedium)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colors.onSurface)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(packs, id: \.id) { pack in
                                        PackRow(
                                            pack: pack,
                                            isSelected: selectedPacks.contains(String(pack.id)),
                                            onSelect: { packId in
                                                if selectedPacks.contains(packId) {
                                                    selectedPacks.remove(packId)
                                                } else {
                                                    selectedPacks.insert(packId)
                                                }
                                            },
                                            theme: colors
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Create Button
                        VStack(spacing: 16) {
                            ModernButton(
                                title: "Create Challenge",
                                icon: "trophy.fill",
                                style: .primary
                            ) {
                                createChallenge()
                            }
                            .disabled(challengeName.isEmpty)
                        }
                        .padding(24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .alert("Challenge Result", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadData() {
        Task {
            do {
                guard let userId = authRepository.authState.userId else {
                    alertMessage = "User not logged in"
                    showAlert = true
                    isLoading = false
                    return
                }
                
                // Load friends
                let friendsFilters: [String: String] = [:]
                let friendsResponse = try await strapiRepository.getFriends(filters: friendsFilters)
                let acceptedFriends = friendsResponse.data.filter { friend in
                    let isSender = friend.sender?.data?.id == userId
                    let isReceiver = friend.receiver?.data?.id == userId
                    let isAccepted = friend.friendsStatus == "Accepted"
                    return (isSender || isReceiver) && isAccepted
                }
                
                // Load packs
                let packsResponse = try await strapiRepository.getPacks(userId: userId)
                
                await MainActor.run {
                    self.friends = acceptedFriends
                    self.packs = packsResponse.data
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to load data: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createChallenge() {
        // TODO: Implement actual challenge creation
        let totalInvites = selectedFriends.count + selectedPacks.count
        alertMessage = "Challenge '\(challengeName)' created and sent to \(totalInvites) recipient\(totalInvites == 1 ? "" : "s")!"
        showAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}



// MARK: - Supporting Views

struct ModernWorkoutStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    @Binding var animateContent: Bool
    let delay: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(FitGlideTheme.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(theme.onSurface)
                
                Text(unit)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Text(title)
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateContent)
    }
}

struct ModernDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(value)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }
}

struct ModernZoneCard: View {
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                Text(subtitle)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
            
            Text(value)
                .font(FitGlideTheme.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface.opacity(0.5))
        )
    }
}

struct ModernAchievementCard: View {
    let title: String
    let icon: String
    let color: Color
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(FitGlideTheme.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    // Simple preview with mock data - no complex dependencies
    VStack(spacing: 20) {
        Text("WorkoutDetailView Preview")
            .font(.title)
            .fontWeight(.bold)
        
        Text("Beautiful modern workout detail view")
            .font(.body)
            .foregroundColor(.secondary)
        
        Text("🇮🇳 Indian wellness design")
            .font(.caption)
            .foregroundColor(.blue)
        
        // Mock workout stats
        HStack(spacing: 20) {
            VStack {
                Text("🏃‍♀️")
                    .font(.title)
                Text("Running")
                    .font(.caption)
            }
            
            VStack {
                Text("🔥")
                    .font(.title)
                Text("500 kcal")
                    .font(.caption)
            }
            
            VStack {
                Text("❤️")
                    .font(.title)
                Text("140 bpm")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    .padding()
}

// MARK: - Helper Functions
func formatDuration(_ time: Float) -> String {
    let totalSeconds = Int(time)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

func calculatePace(_ log: WorkoutLogEntry) -> String {
    let distance = log.distance ?? 0
    let totalTime = log.totalTime ?? 0
    if distance <= 0 || totalTime <= 0 { return "N/A" }
    let pace = totalTime / distance
    let minutes = Int(pace)
    let seconds = Int((pace - Float(minutes)) * 60)
    return String(format: "%d:%02d min/km", minutes, seconds)
}

func heartRateZone(_ log: WorkoutLogEntry, low: Float, high: Float) -> String {
    let maxHr = Float(log.heartRateMaximum ?? 0)
    if maxHr <= 0 { return "N/A" }
    let lowBpm = Int(maxHr * low)
    let highBpm = Int(maxHr * high)
    return "\(lowBpm) - \(highBpm) bpm"
}

func getAchievements(_ log: WorkoutLogEntry) -> [String] {
    var ach: [String] = []
    if (log.distance ?? 0) >= 5 { ach.append("5K Runner 🏃") }
    if (log.distance ?? 0) >= 10 { ach.append("10K Champion 🏅") }
    if (log.calories ?? 0) >= 500 { ach.append("Calorie Crusher 💪") }
    return ach
}

func shareWorkout(_ log: WorkoutLogEntry) {
    // Implementation for sharing workout
    print("Sharing workout: \(log.type ?? "Unknown")")
}

// MARK: - Share Supporting Views
struct FriendRow: View {
    let friend: FriendEntry
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(theme.surfaceVariant)
                        .frame(width: 40, height: 40)
                    
                    Text(String((friend.senderName ?? friend.receiverName ?? "F").prefix(1)))
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                }
                
                // Friend Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(friend.senderName ?? friend.receiverName ?? "Unknown Friend")
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                        
                        // Show online status (we'll assume they're online for now)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : theme.onSurfaceVariant.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PackRow: View {
    let pack: PackEntry
    let isSelected: Bool
    let onSelect: (String) -> Void
    let theme: FitGlideTheme.Colors
    
    var body: some View {
        Button(action: {
            onSelect(String(pack.id))
        }) {
            HStack(spacing: 12) {
                // Pack Icon
                ZStack {
                    Circle()
                        .fill(theme.surfaceVariant)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.onSurface)
                }
                
                // Pack Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    Text("\(pack.gliders?.count ?? 0) members")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : theme.onSurfaceVariant.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
