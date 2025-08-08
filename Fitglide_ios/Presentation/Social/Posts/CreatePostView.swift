//
//  CreatePostView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI
import PhotosUI

struct CreatePostView: View {
    let id = UUID()
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
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
                        // Custom card-like sections instead of Form for more control and modern look
                        contentSection
                        
                        postTypeSection
                        
                        addPhotoSection
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(FitGlideTheme.caption)
                                .foregroundColor(theme.tertiary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(theme.surfaceVariant.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        postButton
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
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
            .onChange(of: viewModel.postSuccess) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Post Content", theme: theme)
            
            TextField("What's on your mind?", text: $viewModel.content, axis: .vertical)
                .font(FitGlideTheme.bodyLarge)
                .padding()
                .frame(minHeight: 120)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius)
                        .stroke(theme.surfaceVariant, lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private var postTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Post Type", theme: theme)
            
            Picker("Post Type", selection: $viewModel.type) {
                Text("Manual").tag("manual")
                Text("Streak").tag("streak")
                Text("Live").tag("live")
            }
            .pickerStyle(.segmented)
            .colorMultiply(theme.primary.opacity(0.8)) // Subtle vibrant tint
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
            .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var addPhotoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Add Photo", theme: theme)
            
            PhotosPicker(selection: $viewModel.imageItem, matching: .images) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.fill")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 20, weight: .medium))
                    
                    Text(viewModel.imageData != nil ? "Image Selected" : "Add Photo")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    if viewModel.imageData != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.quaternary) // Green accent for success
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [theme.surface, theme.surfaceVariant.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Card.cornerRadius))
                .shadow(color: theme.onSurface.opacity(0.08), radius: FitGlideTheme.Card.elevation / 2, x: 0, y: 2)
            }
            .onChange(of: viewModel.imageItem) { newValue in
                Task {
                    guard let item = newValue else { return }
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        viewModel.imageData = data
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var postButton: some View {
        Button(action: {
            Task { await viewModel.createPost() }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.onPrimary))
                }
                Text(viewModel.isLoading ? "Posting..." : "Post")
                    .font(FitGlideTheme.titleMedium)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FitGlideTheme.Button.padding)
            .background(
                LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(theme.onPrimary)
            .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
            .shadow(color: theme.primary.opacity(0.3), radius: FitGlideTheme.Card.elevation, x: 0, y: 4) // Vibrant shadow
            .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal)
    }
}
