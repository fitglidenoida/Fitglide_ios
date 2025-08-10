//
//  AchievementsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var fitCoinsEngine = FitCoinsEngine()
    @StateObject private var levelSystemEngine: LevelSystemEngine
    @StateObject private var achievementsEngine: AchievementsEngine
    
    @State private var selectedTab = 0
    @State private var showFitCoinsWallet = false
    @State private var showLevelDetails = false
    
    init() {
        let fitCoins = FitCoinsEngine()
        let levelSystem = LevelSystemEngine(fitCoinsEngine: fitCoins)
        let achievements = AchievementsEngine(fitCoinsEngine: fitCoins, levelSystemEngine: levelSystem)
        
        self._fitCoinsEngine = StateObject(wrappedValue: fitCoins)
        self._levelSystemEngine = StateObject(wrappedValue: levelSystem)
        self._achievementsEngine = StateObject(wrappedValue: achievements)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with FitCoins
                headerView
                
                // Tab Selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    levelProgressView
                        .tag(0)
                    
                    achievementsGridView
                        .tag(1)
                    
                    fitCoinsHistoryView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showFitCoinsWallet) {
                FitCoinsWalletView(fitCoinsEngine: fitCoinsEngine)
            }
            .sheet(isPresented: $showLevelDetails) {
                LevelDetailsView(levelSystemEngine: levelSystemEngine)
            }
            .overlay(
                // Level Up Animation
                Group {
                    if levelSystemEngine.showLevelUpAnimation,
                       let level = levelSystemEngine.recentlyUnlockedLevel {
                        LevelUpAnimationView(level: level, isShowing: $levelSystemEngine.showLevelUpAnimation)
                    }
                }
            )
            .overlay(
                // Achievement Unlock Animation
                Group {
                    if achievementsEngine.showUnlockAnimation,
                       let achievement = achievementsEngine.recentUnlock {
                        AchievementUnlockView(achievement: achievement, isShowing: $achievementsEngine.showUnlockAnimation)
                    }
                }
            )
            .overlay(
                // FitCoins Transaction Alert
                Group {
                    if fitCoinsEngine.showTransactionAlert,
                       let transaction = fitCoinsEngine.lastTransaction {
                        VStack {
                            Spacer()
                            FitCoinsTransactionAlert(transaction: transaction, isShowing: $fitCoinsEngine.showTransactionAlert)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 100)
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Current Level Display
            if let currentLevel = levelSystemEngine.currentLevel {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currentLevel.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(currentLevel.hindiName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Level Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: levelSystemEngine.getLevelProgress(currentLevel))
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(currentLevel.id)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    showLevelDetails = true
                }
            }
            
            // FitCoins Display
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(fitCoinsEngine.wallet.balance)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("FitCoins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Wallet") {
                    showFitCoinsWallet = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Levels", "Achievements", "History"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = ["Levels", "Achievements", "History"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == ["Levels", "Achievements", "History"].firstIndex(of: tab) ? .semibold : .medium)
                            .foregroundColor(selectedTab == ["Levels", "Achievements", "History"].firstIndex(of: tab) ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == ["Levels", "Achievements", "History"].firstIndex(of: tab) ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Level Progress View
    private var levelProgressView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(levelSystemEngine.levels) { level in
                    LevelProgressCard(
                        level: level,
                        progress: levelSystemEngine.getLevelProgress(level),
                        isCurrentLevel: levelSystemEngine.currentLevel?.id == level.id
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Achievements Grid View
    private var achievementsGridView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Achievement.AchievementCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(achievementsEngine.getAchievementsByCategory(category)) { achievement in
                                AchievementCard(
                                    achievement: achievement,
                                    isUnlocked: achievementsEngine.isAchievementUnlocked(id: achievement.id),
                                    progress: achievementsEngine.getAchievementProgress(id: achievement.id, currentValue: 0) // TODO: Get actual progress
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - FitCoins History View
    private var fitCoinsHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(fitCoinsEngine.getRecentTransactions(limit: 50)) { transaction in
                    FitCoinsTransactionRow(transaction: transaction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - Level Progress Card
struct LevelProgressCard: View {
    let level: Level
    let progress: Double
    let isCurrentLevel: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(level.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if isCurrentLevel {
                            Text("• Current")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(level.hindiName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Level Icon
                ZStack {
                    Circle()
                        .fill(
                            level.isUnlocked ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("\(level.id)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(level.isUnlocked ? .white : .gray)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(progress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(level.achievements.filter { $0.isUnlocked }.count)/\(level.requiredAchievements)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: level.isUnlocked ? .blue : .gray))
                    .scaleEffect(y: 2)
            }
            
            // Reward
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("+\(level.fitCoinsReward) FitCoins")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if level.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(level.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            // Title
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            // Progress
            if !isUnlocked {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
            
            // FitCoins Reward
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                Text("\(achievement.fitCoinsReward)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - FitCoins Transaction Row
struct FitCoinsTransactionRow: View {
    let transaction: FitCoinsTransaction
    
    private var isEarning: Bool {
        return transaction.type == .earned || transaction.type == .bonus
    }
    
    private var iconName: String {
        switch transaction.type {
        case .earned: return "plus.circle.fill"
        case .spent: return "minus.circle.fill"
        case .bonus: return "star.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .earned, .bonus: return .green
        case .spent: return .red
        case .penalty: return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(isEarning ? "+" : "-")\(transaction.amount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(iconColor)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - FitCoins Wallet View
struct FitCoinsWalletView: View {
    @ObservedObject var fitCoinsEngine: FitCoinsEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with balance
                headerView
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    balanceView
                        .tag(0)
                    
                    transactionHistoryView
                        .tag(1)
                    
                    spendingOptionsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("FitCoins Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 20) {
            // Balance Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "wallet.pass.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text("FitCoins Balance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text("\(fitCoinsEngine.wallet.balance)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Stats
                HStack(spacing: 32) {
                    VStack {
                        Text("\(fitCoinsEngine.wallet.totalEarned)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Total Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(fitCoinsEngine.wallet.totalSpent)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        
                        Text("Total Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Quick Stats
            HStack(spacing: 16) {
                WalletStatCard(
                    title: "Today",
                    value: "\(fitCoinsEngine.getTotalEarnedToday())",
                    color: .green
                )
                
                WalletStatCard(
                    title: "This Week",
                    value: "\(fitCoinsEngine.getTotalEarnedThisWeek())",
                    color: .blue
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Balance", "History", "Spend"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = ["Balance", "History", "Spend"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == ["Balance", "History", "Spend"].firstIndex(of: tab) ? .semibold : .medium)
                            .foregroundColor(selectedTab == ["Balance", "History", "Spend"].firstIndex(of: tab) ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == ["Balance", "History", "Spend"].firstIndex(of: tab) ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Balance View
    private var balanceView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Earning Sources
                VStack(alignment: .leading, spacing: 12) {
                    Text("Earning Sources")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        WalletEarningSourceCard(
                            title: "Achievements",
                            description: "Unlock achievements",
                            icon: "trophy.fill",
                            color: .orange
                        )
                        
                        WalletEarningSourceCard(
                            title: "Level Up",
                            description: "Complete levels",
                            icon: "star.fill",
                            color: .purple
                        )
                        
                        WalletEarningSourceCard(
                            title: "Daily Goals",
                            description: "Meet daily targets",
                            icon: "target",
                            color: .green
                        )
                        
                        WalletEarningSourceCard(
                            title: "Streaks",
                            description: "Maintain streaks",
                            icon: "flame.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(fitCoinsEngine.getRecentTransactions(limit: 5)) { transaction in
                            FitCoinsTransactionRow(transaction: transaction)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Transaction History View
    private var transactionHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(fitCoinsEngine.getRecentTransactions(limit: 50)) { transaction in
                    FitCoinsTransactionRow(transaction: transaction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Spending Options View
    private var spendingOptionsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Spending Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spending Options")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                        WalletSpendingOptionCard(
                            title: "Premium Features",
                            description: "Unlock premium features",
                            cost: 100,
                            icon: "crown.fill",
                            color: .yellow
                        )
                        
                        WalletSpendingOptionCard(
                            title: "Custom Themes",
                            description: "Personalize your app",
                            cost: 50,
                            icon: "paintbrush.fill",
                            color: .purple
                        )
                        
                        WalletSpendingOptionCard(
                            title: "Extra Challenges",
                            description: "Create custom challenges",
                            cost: 75,
                            icon: "flag.fill",
                            color: .blue
                        )
                        
                        WalletSpendingOptionCard(
                            title: "Analytics Boost",
                            description: "Enhanced insights",
                            cost: 150,
                            icon: "chart.bar.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal, 20)
                }
                

            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Level Details View
struct LevelDetailsView: View {
    @ObservedObject var levelSystemEngine: LevelSystemEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(levelSystemEngine.levels) { level in
                        LevelDetailCard(level: level, progress: levelSystemEngine.getLevelProgress(level))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Level Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Level Detail Card
struct LevelDetailCard: View {
    let level: Level
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Level Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            level.isUnlocked ?
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 60, height: 60)
                    
                    Text("\(level.id)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(level.isUnlocked ? .white : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(level.hindiName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if level.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            
            // Description
            Text(level.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                
                Text("\(level.achievements.filter { $0.isUnlocked }.count) of \(level.requiredAchievements) achievements completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Achievements List
            VStack(alignment: .leading, spacing: 8) {
                Text("Required Achievements")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(level.achievements) { achievement in
                    HStack {
                        Image(systemName: achievement.isUnlocked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(achievement.isUnlocked ? .green : .gray)
                        
                        Text(achievement.title)
                            .font(.caption)
                            .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text("+\(achievement.fitCoinsReward)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            // Reward
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Level Reward: +\(level.fitCoinsReward) FitCoins")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(level.isUnlocked ? 1.0 : 0.7)
    }
}

#Preview {
    AchievementsView()
}

// MARK: - Wallet Supporting Views
struct WalletStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WalletEarningSourceCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WalletSpendingOptionCard: View {
    let title: String
    let description: String
    let cost: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(cost)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WalletComingSoonCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("SOON")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray)
                .cornerRadius(8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
