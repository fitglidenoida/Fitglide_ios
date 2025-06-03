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

    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        packDetailsSection
                        
                        goalVisibilitySection
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.tertiary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(theme.surfaceVariant.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        createButton
                    }
                    .padding()
                    .scaleEffect(animateForm ? 1.0 : 0.95)
                    .opacity(animateForm ? 1.0 : 0.0)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            animateForm = true
                        }
                    }
                }
            }
            .navigationTitle("Create Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private var packDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Pack Details", theme: theme)
            
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .foregroundColor(theme.primary)
                    .font(.system(size: 20, weight: .medium))
                
                TextField("Pack Name", text: $name)
                    .font(FitGlideTheme.bodyMedium)
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                            .stroke(theme.surfaceVariant, lineWidth: 1)
                    )
                    .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(theme.primary)
                    .font(.system(size: 20, weight: .medium))
                
                TextField("Description (optional)", text: $description)
                    .font(FitGlideTheme.bodyMedium)
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                            .stroke(theme.surfaceVariant, lineWidth: 1)
                    )
                    .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
    }
    
    private var goalVisibilitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Goal & Visibility", theme: theme)
            
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .foregroundColor(theme.secondary)
                    .font(.system(size: 20, weight: .medium))
                
                Text("Goal")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Text("\(goal)")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.surfaceVariant.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Stepper("", value: $goal, in: 1000...100000, step: 500)
                    .tint(theme.primary)
                    .labelsHidden()
            }
            .padding()
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            
            Toggle(isOn: $isPublic) {
                HStack(spacing: 12) {
                    Image(systemName: isPublic ? "globe" : "lock")
                        .foregroundColor(theme.quaternary)
                        .font(.system(size: 20, weight: .medium))
                    Text("Make Public")
                        .font(FitGlideTheme.bodyLarge)
                        .foregroundColor(theme.onSurface)
                }
            }
            .tint(theme.primary)
            .padding()
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var createButton: some View {
        Button(action: {
            Task {
                await createPack()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.onPrimary))
                }
                Text(isLoading ? "Creating..." : "Create Pack")
                    .font(FitGlideTheme.titleMedium)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitGlideTheme.Button.padding)
            .background(
                LinearGradient(gradient: Gradient(colors: name.isEmpty || isLoading ? [theme.surfaceVariant] : [theme.primary, theme.secondary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(name.isEmpty || isLoading ? theme.onSurfaceVariant : theme.onPrimary)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
            .shadow(color: theme.primary.opacity(0.3), radius: FitGlideTheme.Card.elevation, x: 0, y: 4) // Vibrant shadow
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .disabled(name.isEmpty || isLoading)
        .padding(.horizontal)
    }
    
    // MARK: - Submit Pack
    private func createPack() async {
        guard !name.isEmpty else {
            errorMessage = "Name is required"
            return
        }
        
        guard let userId = viewModel.authRepository.authState.userId else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = PackRequest(
            name: name,
            goal: goal,
            gliders: [UserId(id: userId)],                    // Only the creator for now
            captain: UserId(id: userId),                      // Creator is captain
            description: description.isEmpty ? nil : description,
            visibility: isPublic ? "public" : "private",
            logo: nil                                         // Can be implemented later
        )
        
        do {
            _ = try await viewModel.strapiRepository.postPack(request: request)
            await viewModel.fetchPacks()
            dismiss()
        } catch {
            errorMessage = "Failed to create pack: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
