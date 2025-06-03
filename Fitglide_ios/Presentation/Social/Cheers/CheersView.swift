//
//  CheersView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct CheersView: View {
    @ObservedObject var viewModel: CheersViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: FitGlideTheme.Colors {
        FitGlideTheme.colors(for: colorScheme)
    }
    
    private func initials(for id: String?) -> String {
        guard let id = id else { return "?" }
        return String(id.prefix(2)).uppercased()
    }
    
    private func CheerCardView(cheer: CheerEntry) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(theme.primary)
                .frame(width: 40, height: 40)
                .overlay(Text(initials(for: cheer.sender.id)))
            VStack(alignment: .leading, spacing: 4) {
                Text(cheer.message)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurface)
                
                Text((cheer.type?.capitalized ?? "Text") + (cheer.isLive == true ? " • Live" : ""))
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding()
        .background(theme.surfaceVariant)
        .cornerRadius(12)
    }
    
    
    private func CheersListView() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.cheersList) { cheer in
                    CheerCardView(cheer: cheer)
                }
            }
            .padding()
        }
    }
    
    
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.isLoading {
                ProgressView("Loading cheers...")
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.cheersList.isEmpty {
                Spacer()
                Text("No cheers yet — get moving and spread some love!")
                    .multilineTextAlignment(.center)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(theme.onSurfaceVariant)
                Spacer()
            } else {
                CheersListView()
            }
        }
        .navigationTitle("Cheers")
        .task {
            await viewModel.loadCheers()
        }
    }
}
