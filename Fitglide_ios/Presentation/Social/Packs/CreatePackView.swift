//
//  CreatePackView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct CreatePackView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: PacksViewModel
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var goal: Int = 10000
    @State private var isPublic: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var animateForm = false
    @State private var showIndianWisdom = false

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
                            
                            // Pack Details Card
                            packDetailsCard
                            
                            // Goal & Visibility Card
                            goalVisibilityCard
                            
                            // Error Message
                            if let error = errorMessage {
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
                    Text("Create Wolf Pack 🐺")
                        .font(FitGlideTheme.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                        .offset(x: animateForm ? 0 : -20)
                        .opacity(animateForm ? 1.0 : 0.0)
                    
                    Text("Lead your pack, inspire your gliders")
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
                
                Text("Pack Wisdom")
                    .font(FitGlideTheme.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Text("A pack that moves together, grows together. Lead with strength, inspire with wisdom.")
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
    
    // MARK: - Pack Details Card
    var packDetailsCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Pack Details")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Pack Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pack Name")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .foregroundColor(theme.primary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Enter pack name", text: $name)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                    }
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.surfaceVariant, lineWidth: 1)
                    )
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(theme.primary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Describe your pack's mission", text: $description)
                            .font(FitGlideTheme.bodyMedium)
                            .foregroundColor(theme.onSurface)
                    }
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.surfaceVariant, lineWidth: 1)
                    )
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
    
    // MARK: - Goal & Visibility Card
    var goalVisibilityCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                Text("Pack Goals & Settings")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Daily Goal
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Step Goal")
                        .font(FitGlideTheme.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(theme.onSurface)
                    
                    HStack {
                        Text("\(goal) steps")
                            .font(FitGlideTheme.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primary)
                        
                        Spacer()
                        
                        Stepper("", value: $goal, in: 5000...20000, step: 500)
                            .labelsHidden()
                    }
                    .padding(16)
                    .background(theme.surfaceVariant.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Visibility Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Public Pack")
                            .font(FitGlideTheme.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                        
                        Text("Anyone can discover and join")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPublic)
                        .tint(theme.primary)
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateForm)
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
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateForm)
    }
    
    // MARK: - Create Button
    var createButton: some View {
        Button(action: createPack) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.onPrimary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isLoading ? "Creating Pack..." : "Create Wolf Pack")
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
        .disabled(isLoading || name.isEmpty)
        .opacity((isLoading || name.isEmpty) ? 0.6 : 1.0)
        .offset(y: animateForm ? 0 : 20)
        .opacity(animateForm ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateForm)
    }
    
    // MARK: - Actions
    private func createPack() {
        guard !name.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.createPack(
                    name: name,
                    description: description,
                    goal: goal,
                    isPublic: isPublic
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
