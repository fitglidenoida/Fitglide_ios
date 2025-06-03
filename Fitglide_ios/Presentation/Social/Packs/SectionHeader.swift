//
//  SectionHeader.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 13/07/25.
//

import Foundation
import SwiftUI

struct SectionHeader: View {
    let title: String
    let theme: FitGlideTheme.Colors

    var body: some View {
        Text(title)
            .font(FitGlideTheme.titleMedium)
            .foregroundColor(theme.onBackground)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
