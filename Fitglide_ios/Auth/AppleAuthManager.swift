//
//  AppleAuthManager.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 03/06/25.
//

import Foundation
import AuthenticationServices
import UIKit

class AppleAuthManager: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var completion: ((Result<AppleSignInResult, Error>) -> Void)?

    struct AppleSignInResult {
        let identityToken: String
        let userId: String
        let email: String?
        let firstName: String?
        let lastName: String?
    }
    
    func startSignIn(from viewController: UIViewController, completion: @escaping (Result<AppleSignInResult, Error>) -> Void) {
        self.completion = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID credential"])))
            return
        }

        print("🍏 Apple Identity Token:\n\(identityToken)") // ✅ PRINT THIS

        let result = AppleSignInResult(
            identityToken: identityToken,
            userId: appleIDCredential.user,
            email: appleIDCredential.email,
            firstName: appleIDCredential.fullName?.givenName,
            lastName: appleIDCredential.fullName?.familyName
        )
        completion?(.success(result))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow()
    }
}
