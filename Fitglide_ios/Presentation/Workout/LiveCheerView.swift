//
//  LiveCheerView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 09/07/25.
//

import Foundation
import SwiftUI

struct LiveCheerView: View {
    @ObservedObject var liveCheerService: LiveCheerService
    let colors: FitGlideTheme.Colors
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                Text("Live Cheers")
                    .font(FitGlideTheme.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.onSurface)
                
                Spacer()
                
                Button(action: {
                    liveCheerService.toggleLiveCheer()
                }) {
                    Image(systemName: liveCheerService.isLiveCheerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundColor(liveCheerService.isLiveCheerEnabled ? colors.primary : colors.onSurfaceVariant)
                }
            }
            
            // Cheers List
            if liveCheerService.activeCheers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("No cheers yet")
                        .font(FitGlideTheme.bodyMedium)
                        .foregroundColor(colors.onSurfaceVariant)
                    
                    Text("Share your workout to get cheers from friends!")
                        .font(FitGlideTheme.caption)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(liveCheerService.activeCheers.prefix(5)) { cheer in
                            CheerRow(cheer: cheer, colors: colors)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.onSurface.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct CheerRow: View {
    let cheer: LiveCheer
    let colors: FitGlideTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar or Icon
            ZStack {
                Circle()
                    .fill(cheerTypeColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: cheerTypeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(cheerTypeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cheer.message)
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurface)
                    .lineLimit(2)
                
                Text(timeAgoString)
                    .font(FitGlideTheme.caption)
                    .foregroundColor(colors.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.surface.opacity(0.5))
        )
    }
    
    private var cheerTypeColor: Color {
        switch cheer.type {
        case .motivation:
            return .blue
        case .achievement:
            return .yellow
        case .challenge:
            return .purple
        case .milestone:
            return .green
        }
    }
    
    private var cheerTypeIcon: String {
        switch cheer.type {
        case .motivation:
            return "heart.fill"
        case .achievement:
            return "trophy.fill"
        case .challenge:
            return "flag.fill"
        case .milestone:
            return "star.fill"
        }
    }
    
    private var timeAgoString: String {
        let timeInterval = Date().timeIntervalSince(cheer.timestamp)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        }
    }
} 