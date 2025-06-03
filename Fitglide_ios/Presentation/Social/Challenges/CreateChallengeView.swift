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
    let onDismiss: () -> Void
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: SectionHeader(title: "Challenge Type", theme: theme)) {
                        Picker("Challenge Type", selection: $viewModel.type) {
                            ForEach(viewModel.allowedTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(theme.primary)
                    }
                    
                    Section(header: SectionHeader(title: "Metric & Goal", theme: theme)) {
                        Picker("Metric", selection: $viewModel.metric) {
                            ForEach(viewModel.availableMetrics, id: \.self) { metric in
                                Text(metric.capitalized).tag(metric)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(theme.secondary)
                        
                        HStack {
                            Label("Goal", systemImage: "target")
                                .foregroundColor(theme.tertiary)
                                .font(FitGlideTheme.bodyLarge)
                            Spacer()
                            Text("\(viewModel.goal)")
                                .font(FitGlideTheme.bodyMedium)
                                .foregroundColor(theme.onSurface)
                            Stepper("", value: $viewModel.goal, in: 100...100000, step: 100)
                                .tint(theme.quaternary)
                                .labelsHidden()
                        }
                    }
                    
                    Section(header: SectionHeader(title: "Dates", theme: theme)) {
                        DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                            .tint(theme.primary)
                        DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                            .tint(theme.primary)
                    }
                    
                    if viewModel.type == "Solo" || viewModel.type == "Public" {
                        Section(header: SectionHeader(title: "Challengee", theme: theme)) {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)
                                TextField("Challengee Email (optional)", text: $viewModel.challengeeEmail)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(theme.surfaceVariant.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    } else if viewModel.type == "PackVsPack" {
                        Section(header: SectionHeader(title: "Opponent Pack", theme: theme)) {
                            HStack {
                                Image(systemName: "person.3")
                                    .foregroundColor(theme.primary)
                                    .frame(width: 24)
                                TextField("Opponent Pack ID", text: Binding(
                                    get: { viewModel.challengeePackId ?? "" },
                                    set: { viewModel.challengeePackId = $0 }
                                ))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(theme.surfaceVariant.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(FitGlideTheme.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.createChallenge()
                            if viewModel.success {
                                onDismiss()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.onPrimary))
                            }
                            Text(viewModel.isLoading ? "Creating..." : "Create Challenge")
                                .font(FitGlideTheme.titleMedium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [theme.primary, theme.secondary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(viewModel.isLoading ? theme.onSurfaceVariant : theme.onPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FitGlideTheme.Button.cornerRadius))
                        .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .disabled(viewModel.isLoading)
                    .listRowInsets(EdgeInsets())
                }
                
                if viewModel.selectedPackId == nil && viewModel.type != "Solo" && viewModel.type != "Public" {
                    VStack {
                        Spacer()
                        Text("Missing selected pack ID")
                            .font(FitGlideTheme.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background.ignoresSafeArea())
            .scaleEffect(animateForm ? 1.0 : 0.95)
            .opacity(animateForm ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animateForm = true
                }
            }
        }
    }
}
