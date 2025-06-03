//
//  AppleAuthManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct LoginView: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authRepository = AuthRepository(appleAuthManager: AppleAuthManager())
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        let colors = FitGlideTheme.colors(for: colorScheme)

        VStack(spacing: 20) {
            Spacer()
            Image("Fitglide_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)

            Text("Login to FitGlide")
                .font(FitGlideTheme.titleLarge)
                .foregroundColor(colors.onBackground)

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { _ in
                    authRepository.loginWithApple { success in
                        if success {
                            navigationViewModel.navigateToMainApp()
                        } else {
                            alertMessage = "Login failed."
                            showingAlert = true
                        }
                    }
                }
            )
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.primary, lineWidth: 1)
            )
            .padding(.horizontal)

            Button(action: {
                print("Navigate to onboarding")
            }) {
                Text("Need an account? Sign up")
                    .font(FitGlideTheme.bodyLarge)
                    .foregroundColor(colors.primary)
            }

            Spacer()
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Authentication"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if authRepository.isLoggedIn() {
                navigationViewModel.navigateToMainApp()
                print("User is logged in, navigating to main app")
            }
        }
    }
}


#Preview {
    LoginView(navigationViewModel: NavigationViewModel())
}
