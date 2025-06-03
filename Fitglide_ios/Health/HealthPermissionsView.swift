//
//  HealthPermissionsView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/06/25.
//

import Foundation
import SwiftUI
import HealthKit
import os.log

struct HealthPermissionsView: View {
    @StateObject private var viewModel: HealthPermissionsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    init(viewModel: HealthPermissionsViewModel = HealthPermissionsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)
        ZStack {
            colors.background
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("FitGlide needs HealthKit permissions to track your steps, sleep, exercise, and heart rate.")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Please go to Settings > Health > Data Access & Devices, select FitGlide, and allow access.")
                    .font(FitGlideTheme.bodyMedium)
                    .foregroundColor(colors.onSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Button(action: {
                    viewModel.openHealthSettings()
                    dismiss()
                }) {
                    Text("Open Health Settings")
                        .font(FitGlideTheme.bodyLarge)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colors.primary)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding()
        }
    }
}

class HealthPermissionsViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.fitglide", category: "HealthPermissionsViewModel")

    func openHealthSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            logger.error("Invalid settings URL")
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL) { success in
                self.logger.info("Opening Health settings: \(success)")
            }
        } else {
            logger.error("Cannot open settings URL")
        }
    }
}

struct HealthPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthPermissionsView()
            .previewDisplayName("Health Permissions View")
    }
}
