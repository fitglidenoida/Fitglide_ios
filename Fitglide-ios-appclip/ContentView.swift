//
//  ContentView.swift
//  Fitglide-ios-appclip
//
//  Created by Sandip Tiwari on 11/08/25.
//

import SwiftUI

struct AppClipView: View {
    @State private var currentStep = 0
    @State private var showDownloadButton = false
    
    private let features = [
        AppClipFeature(
            icon: "figure.walk",
            title: "Step Tracking",
            description: "Track your daily steps and activity with precision",
            color: .blue
        ),
        AppClipFeature(
            icon: "heart.fill",
            title: "Health Monitoring",
            description: "Monitor heart rate, sleep quality, and hydration levels",
            color: .red
        ),
        AppClipFeature(
            icon: "trophy.fill",
            title: "Achievements",
            description: "Earn badges and FitCoins for your fitness milestones",
            color: .orange
        ),
        AppClipFeature(
            icon: "person.2.fill",
            title: "Social Features",
            description: "Connect with friends, join challenges, and share progress",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Feature showcase
                TabView(selection: $currentStep) {
                    ForEach(0..<features.count, id: \.self) { index in
                        FeatureShowcaseView(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 400)
                
                // Download section
                downloadSection
            }
        }
        .onAppear {
            startAutoScroll()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("FitGlide")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Your Personal Fitness Companion")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
    }
    
    private var downloadSection: some View {
        VStack(spacing: 20) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(currentStep == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            
            // Download button
            Button(action: {
                // Open App Store
                if let url = URL(string: "https://apps.apple.com/app/fitglide") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                    
                    Text("Download Full App")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Text("Experience the complete FitGlide journey with all features")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
    
    private func startAutoScroll() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentStep = (currentStep + 1) % features.count
            }
        }
    }
}

struct AppClipFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct FeatureShowcaseView: View {
    let feature: AppClipFeature
    
    var body: some View {
        VStack(spacing: 30) {
            // Feature icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 60))
                    .foregroundColor(feature.color)
            }
            
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    AppClipView()
}
