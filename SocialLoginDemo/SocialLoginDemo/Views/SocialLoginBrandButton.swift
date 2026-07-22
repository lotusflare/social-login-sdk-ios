import AuthenticationServices
import SocialLoginSDK
import SwiftUI
import UIKit

struct GoogleSignInBrandButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                GoogleLogoMark()
                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SocialBrandColors.googleText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(SocialBrandColors.googleBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

struct FacebookSignInBrandButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                FacebookLogoMark()
                Text("Continue with Facebook")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(SocialBrandColors.facebookText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(SocialBrandColors.facebookBlue)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct AppleSignInBrandButton: UIViewRepresentable {
    let isEnabled: Bool
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 4
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1 : 0.45
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        uiView.isEnabled = isEnabled
        uiView.alpha = isEnabled ? 1 : 0.45
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTap() {
            action()
        }
    }
}

struct SocialLoginButtonsSection: View {
    let isLoading: Bool
    let onSignIn: (SocialLoginProvider) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sign In")
                .font(.headline)

            VStack(spacing: 12) {
                GoogleSignInBrandButton(isEnabled: !isLoading) {
                    onSignIn(.google)
                }

                FacebookSignInBrandButton(isEnabled: !isLoading) {
                    onSignIn(.facebook)
                }

                AppleSignInBrandButton(isEnabled: !isLoading) {
                    onSignIn(.apple)
                }
                .frame(height: 44)
            }
        }
    }
}
