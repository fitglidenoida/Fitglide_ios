//
//  FABSubButtonStyle.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct FABSubButtonStyle: ButtonStyle {
    let theme: FitGlideTheme.Colors

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.surface)
            .foregroundColor(theme.onSurface)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
}
