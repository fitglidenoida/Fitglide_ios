//
//  FitCoinsEngine.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 19/07/25.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - FitCoins Engine
@MainActor
class FitCoinsEngine: ObservableObject {
    @Published var wallet: FitCoinsWallet
    @Published var showTransactionAlert = false
    @Published var lastTransaction: FitCoinsTransaction?
    
    private let userDefaults = UserDefaults.standard
    private let logger = Logger(subsystem: "com.trailblazewellness.fitglide", category: "FitCoinsEngine")
    
    init() {
        // Initialize with default wallet
        self.wallet = FitCoinsWallet(
            balance: 0,
            totalEarned: 0,
            totalSpent: 0,
            transactionHistory: []
        )
        loadWallet()
    }
    
    // MARK: - Earning FitCoins
    func earnFitCoins(amount: Int, reason: String, achievementId: String? = nil) {
        let transaction = FitCoinsTransaction(
            id: UUID().uuidString,
            amount: amount,
            type: .earned,
            description: reason,
            date: Date(),
            relatedAchievement: achievementId
        )
        
        wallet = FitCoinsWallet(
            balance: self.wallet.balance + amount,
            totalEarned: self.wallet.totalEarned + amount,
            totalSpent: self.wallet.totalSpent,
            transactionHistory: self.wallet.transactionHistory + [transaction]
        )
        
        saveWallet()
        showTransactionAlert = true
        lastTransaction = transaction
        
        logger.info("Earned \(amount) FitCoins for: \(reason)")
        
        // Hide alert after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showTransactionAlert = false
            self.lastTransaction = nil
        }
    }
    
    // MARK: - Spending FitCoins
    func spendFitCoins(amount: Int, reason: String) -> Bool {
        guard self.wallet.balance >= amount else {
            logger.warning("Insufficient FitCoins balance. Required: \(amount), Available: \(self.wallet.balance)")
            return false
        }
        
        let transaction = FitCoinsTransaction(
            id: UUID().uuidString,
            amount: amount,
            type: .spent,
            description: reason,
            date: Date(),
            relatedAchievement: nil
        )
        
        wallet = FitCoinsWallet(
            balance: self.wallet.balance - amount,
            totalEarned: self.wallet.totalEarned,
            totalSpent: self.wallet.totalSpent + amount,
            transactionHistory: self.wallet.transactionHistory + [transaction]
        )
        
        saveWallet()
        logger.info("Spent \(amount) FitCoins for: \(reason)")
        return true
    }
    
    // MARK: - Bonus FitCoins
    func awardBonus(amount: Int, reason: String) {
        let transaction = FitCoinsTransaction(
            id: UUID().uuidString,
            amount: amount,
            type: .bonus,
            description: reason,
            date: Date(),
            relatedAchievement: nil
        )
        
        wallet = FitCoinsWallet(
            balance: self.wallet.balance + amount,
            totalEarned: self.wallet.totalEarned + amount,
            totalSpent: self.wallet.totalSpent,
            transactionHistory: self.wallet.transactionHistory + [transaction]
        )
        
        saveWallet()
        logger.info("Awarded \(amount) bonus FitCoins for: \(reason)")
    }
    
    // MARK: - Penalties
    func applyPenalty(amount: Int, reason: String) {
        let actualPenalty = min(amount, self.wallet.balance) // Can't go below 0
        
        let transaction = FitCoinsTransaction(
            id: UUID().uuidString,
            amount: actualPenalty,
            type: .penalty,
            description: reason,
            date: Date(),
            relatedAchievement: nil
        )
        
        wallet = FitCoinsWallet(
            balance: self.wallet.balance - actualPenalty,
            totalEarned: self.wallet.totalEarned,
            totalSpent: self.wallet.totalSpent + actualPenalty,
            transactionHistory: self.wallet.transactionHistory + [transaction]
        )
        
        saveWallet()
        logger.info("Applied \(actualPenalty) FitCoins penalty for: \(reason)")
    }
    
    // MARK: - Achievement Rewards
    func rewardAchievement(_ achievement: Achievement) {
        earnFitCoins(
            amount: achievement.fitCoinsReward,
            reason: "Achievement: \(achievement.title)",
            achievementId: achievement.id
        )
    }
    
    // MARK: - Level Completion Rewards
    func rewardLevelCompletion(_ level: Level) {
        earnFitCoins(
            amount: level.fitCoinsReward,
            reason: "Level \(level.id) Complete: \(level.name)",
            achievementId: nil
        )
    }
    
    // MARK: - Persistence
    private func saveWallet() {
        do {
            let data = try JSONEncoder().encode(self.wallet)
            userDefaults.set(data, forKey: "fitCoinsWallet")
        } catch {
            logger.error("Failed to save FitCoins wallet: \(error.localizedDescription)")
        }
    }
    
    private func loadWallet() {
        guard let data = userDefaults.data(forKey: "fitCoinsWallet") else {
            return // Use default wallet from init
        }
        
        do {
            self.wallet = try JSONDecoder().decode(FitCoinsWallet.self, from: data)
        } catch {
            logger.error("Failed to load FitCoins wallet: \(error.localizedDescription)")
            // Keep default wallet
        }
    }
    
    // MARK: - Utility Methods
    func canAfford(_ amount: Int) -> Bool {
        return self.wallet.balance >= amount
    }
    
    func getRecentTransactions(limit: Int = 10) -> [FitCoinsTransaction] {
        return Array(self.wallet.transactionHistory.suffix(limit))
    }
    
    func getTransactionsByType(_ type: FitCoinsTransaction.TransactionType) -> [FitCoinsTransaction] {
        return self.wallet.transactionHistory.filter { $0.type == type }
    }
    
    func getTotalEarnedToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return self.wallet.transactionHistory
            .filter { $0.type == .earned && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getTotalEarnedThisWeek() -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return self.wallet.transactionHistory
            .filter { $0.type == .earned && $0.date >= weekAgo }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Reset (for testing)
    func resetWallet() {
        wallet = FitCoinsWallet(
            balance: 0,
            totalEarned: 0,
            totalSpent: 0,
            transactionHistory: []
        )
        saveWallet()
        logger.info("FitCoins wallet reset")
    }
}

// MARK: - FitCoins Transaction Alert View
struct FitCoinsTransactionAlert: View {
    let transaction: FitCoinsTransaction
    @Binding var isShowing: Bool
    
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
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(isEarning ? "+" : "-")\(transaction.amount) FitCoins")
                    .font(.caption)
                    .foregroundColor(iconColor)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isShowing ? 1.0 : 0.8)
        .opacity(isShowing ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
    }
}
