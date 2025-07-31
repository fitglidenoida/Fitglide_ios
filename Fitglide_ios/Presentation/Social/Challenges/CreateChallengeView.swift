//
//  CreateChallengeView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct CreateChallengeView: View {
    @ObservedObject var viewModel: CreateChallengeViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var animateForm = false
    @State private var showIndianWisdom = false
    let onDismiss: () -> Void
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with Indian wellness gradient
                LinearGradient(
                    colors: [
                        theme.background,
                        theme.surface.opacity(0.3),
                        theme.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header Section
                    modernHeaderSection
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Indian Wisdom Quote
                            if showIndianWisdom {
                                indianWisdomQuoteCard
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Challenge Type Card
                            challengeTypeCard
                            
                            // Metric & Goal Card
                            metricGoalCard
                            
                            // Dates Card
                            datesCard
                            
                            // Challengee Card (conditional)
                            if viewModel.type == "Solo" || viewModel.type == "Public" {
                                challengeeCard
                            } else if viewModel.type == "PackVsPack" {
                                opponentPackCard
                            }
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                errorMessageCard(error: error)
                            }
                            
                            // Create Button
                            createButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateForm = true
                }
                
                // Show Indian wisdom after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showIndianWisdom = true
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Modern Header Section
    var modernHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Challenge 🏆")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateForm ? 0 : -20)
                        .opacity(animateForm ? 1.0 : 0.0)
                    
                    Text("Push limits, inspire greatness")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurfaceVariant)
                        .offset(x: animateForm ? 0 : -20)
                        .opacity(animateForm ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Close Button
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(theme.surface)
                            .frame(width: 44, height: 44)
                            .shadow(color: theme.onSurface.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.onSurface)
                    }
                }
                .scaleEffect(animateForm ? 1.0 : 0.8)
                .opacity(animateForm ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
        .background(
            theme.background
                .shadow(color: theme.onSurface.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Indian Wisdom Quote Card
    var indianWisdomQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                Text("Challenge Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text("Every challenge is an opportunity to discover your true potential. Rise above, inspire others.")
                .font(FitGlideTheme.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Challenge Type Card
    var challengeTypeCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Challenge Type")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.allowedTypes, id: \.self) { type in
                    Button(action: {
                        viewModel.type = type
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.capitalized)
                                    .font(FitGlideTheme.bodyLarge)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.onSurface)
                                
                                Text(challengeTypeDescription(for: type))
                                    .font(FitGlideTheme.caption)
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                            
                            Spacer()
                            
                            if viewModel.type == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primary)
                                    .font(.system(size: 20, weight: .medium))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.type == type ? theme.primary.opacity(0.1) : theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.type == type ? theme.primary : theme.surfaceVariant, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateForm)
    }
    
    // MARK: - Metric & Goal Card
    var metricGoalCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Metric & Goal")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Metric Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Metric")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    Menu {
                        ForEach(viewModel.availableMetrics, id: \.self) { metric in
                            Button(action: {
                                viewModel.metric = metric
                            }) {
                                Label(metric.capitalized, systemImage: metricIcon(for: metric))
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: metricIcon(for: viewModel.metric))
                                .foregroundColor(theme.primary)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(viewModel.metric.capitalized)
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurface)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(theme.onSurfaceVariant)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(16)
                        .background(theme.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Goal Stepper
                VStack(alignment: .leading, spacing: 8) {
                    Text("Challenge Goal")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    HStack {
                        Text("\(viewModel.goal)")
                            .font(FitGlideTheme.titleLarge)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primary)
                        
                        Text(goalUnit(for: viewModel.metric))
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        Spacer()
                        
                        Stepper("", value: $viewModel.goal, in: 100...100000, step: goalStep(for: viewModel.metric))
                            .labelsHidden()
                    }
                    .padding(16)
                    .background(theme.surfaceVariant.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateForm)
    }
    
    // MARK: - Dates Card
    var datesCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Challenge Dates")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Start Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Date")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .tint(theme.primary)
                        .padding(16)
                        .background(theme.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // End Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .tint(theme.primary)
                        .padding(16)
                        .background(theme.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateForm)
    }
    
    // MARK: - Challengee Card
    var challengeeCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Challenge Opponent")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Opponent Email (Optional)")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Enter opponent's email", text: $viewModel.challengeeEmail)
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(16)
                .background(theme.surfaceVariant.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateForm)
    }
    
    // MARK: - Opponent Pack Card
    var opponentPackCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Opponent Pack")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Opponent Pack ID")
                    .font(FitGlideTheme.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                
                HStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Enter opponent pack ID", text: Binding(
                        get: { viewModel.challengeePackId ?? "" },
                        set: { viewModel.challengeePackId = $0 }
                    ))
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
                }
                .padding(16)
                .background(theme.surfaceVariant.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateForm)
    }
    
    // MARK: - Error Message Card
    func errorMessageCard(error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(theme.tertiary)
                .font(.system(size: 16, weight: .medium))
            
            Text(error)
                .font(FitGlideTheme.bodyMedium)
                .foregroundColor(theme.tertiary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tertiary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.tertiary.opacity(0.3), lineWidth: 1)
        )
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateForm)
    }
    
    // MARK: - Create Button
    var createButton: some View {
        Button(action: createChallenge) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.onPrimary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Creating Challenge..." : "Create Challenge")
                    .font(FitGlideTheme.bodyLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(theme.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateForm)
    }
    
    // MARK: - Actions
    private func createChallenge() {
        Task {
            await viewModel.createChallenge()
            await MainActor.run {
                onDismiss()
            }
        }
    }
    
    // MARK: - Helper Functions
    private func challengeTypeDescription(for type: String) -> String {
        switch type {
        case "Solo": return "Challenge yourself to reach new heights"
        case "Public": return "Open challenge for anyone to join"
        case "PackVsPack": return "Pack against pack competition"
        case "IntraPack": return "Challenge within your own pack"
        default: return "Fitness challenge"
        }
    }
    
    private func metricIcon(for metric: String) -> String {
        switch metric {
        case "steps": return "figure.walk"
        case "calories": return "flame.fill"
        case "distance": return "location.fill"
        case "workouts": return "dumbbell.fill"
        default: return "target"
        }
    }
    
    private func goalUnit(for metric: String) -> String {
        switch metric {
        case "steps": return "steps"
        case "calories": return "calories"
        case "distance": return "km"
        case "workouts": return "workouts"
        default: return "units"
        }
    }
    
    private func goalStep(for metric: String) -> Int {
        switch metric {
        case "steps": return 100
        case "calories": return 50
        case "distance": return 1
        case "workouts": return 1
        default: return 100
        }
    }
}
