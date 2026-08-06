import FacebookCore
import FacebookLogin
import Foundation
import UIKit

final class FacebookLoginProvider: SocialLoginProviderType {
    private var configuration: SocialLoginConfiguration?
    private let loginManager = LoginManager()

    func configure(with configuration: SocialLoginConfiguration) {
        self.configuration = configuration
        applyFacebookSettings(from: configuration)
        Profile.enableUpdatesOnAccessTokenChange(true)
    }

    /// Forces Facebook Limited Login. `rawNonce` is passed into `LoginConfiguration` (OIDC claim)
    /// and attached to the payload for the backend login body.
    func signIn(
        from viewController: UIViewController,
        rawNonce: String,
        completion: @escaping (Result<ProviderAuthPayload, SocialLoginError>) -> Void
    ) {
        guard configuration != nil else {
            completion(.failure(.notConfigured))
            return
        }

        guard hasFacebookCredentials() else {
            completion(.failure(.missingProviderConfiguration(.facebook)))
            return
        }

        guard !rawNonce.isEmpty else {
            completion(
                .failure(.providerSignInFailed(.facebook, message: "Missing social nonce for Limited Login."))
            )
            return
        }

        guard let loginConfiguration = makeLimitedLoginConfiguration(rawNonce: rawNonce) else {
            completion(.failure(.providerSignInFailed(.facebook, message: "Invalid Facebook login configuration.")))
            return
        }

        loginManager.logIn(viewController: viewController, configuration: loginConfiguration) { result in
            switch result {
            case .cancelled:
                completion(.failure(.cancelled))
            case .failed(let error):
                completion(.failure(.providerSignInFailed(.facebook, message: error.localizedDescription)))
            case .success:
                guard let authenticationToken = AuthenticationToken.current,
                      !authenticationToken.tokenString.isEmpty else {
                    completion(
                        .failure(
                            .providerSignInFailed(.facebook, message: "Missing Facebook authentication token.")
                        )
                    )
                    return
                }
                Self.completeWithLimitedLogin(
                    authenticationToken: authenticationToken,
                    rawNonce: rawNonce,
                    completion: completion
                )
            }
        }
    }

    func signOut() {
        loginManager.logOut()
    }

    func handleOpenURL(_ url: URL) -> Bool {
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            options: [:]
        )
    }

    private func hasFacebookCredentials() -> Bool {
        guard let configuration else { return false }
        let appID = configuration.facebookAppID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let clientToken = configuration.facebookClientToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !appID.isEmpty && !clientToken.isEmpty
    }

    private func applyFacebookSettings(from configuration: SocialLoginConfiguration) {
        if let appID = configuration.facebookAppID?.trimmingCharacters(in: .whitespacesAndNewlines), !appID.isEmpty {
            Settings.shared.appID = appID
        }
        if let clientToken = configuration.facebookClientToken?.trimmingCharacters(in: .whitespacesAndNewlines),
           !clientToken.isEmpty {
            Settings.shared.clientToken = clientToken
        }
    }

    /// Always uses Limited Login so ATT authorization does not control the credential type.
    private func makeLimitedLoginConfiguration(rawNonce: String) -> LoginConfiguration? {
        guard let configuration else { return nil }

        let permissions = configuration.facebook.permissions.map(Self.mapPermission)
        return LoginConfiguration(
            permissions: Set(permissions),
            tracking: .limited,
            nonce: rawNonce
        )
    }

    private static func completeWithLimitedLogin(
        authenticationToken: AuthenticationToken,
        rawNonce: String,
        completion: @escaping (Result<ProviderAuthPayload, SocialLoginError>) -> Void
    ) {
        Profile.loadCurrentProfile { profile, error in
            if let error {
                completion(.failure(.providerSignInFailed(.facebook, message: error.localizedDescription)))
                return
            }

            let resolvedProfile = profile ?? Profile.current
            let claims = authenticationToken.claims()
            let userID = resolvedProfile?.userID ?? claims?.sub ?? ""
            guard !userID.isEmpty else {
                completion(
                    .failure(.providerSignInFailed(.facebook, message: "Missing Facebook user identifier."))
                )
                return
            }

            completion(
                .success(
                    ProviderAuthPayload(
                        provider: .facebook,
                        userID: userID,
                        email: resolvedProfile?.email ?? claims?.email,
                        idToken: authenticationToken.tokenString,
                        nonce: rawNonce,
                        userName: displayName(from: resolvedProfile, claims: claims)
                    )
                )
            )
        }
    }

    private static func displayName(
        from profile: Profile?,
        claims: AuthenticationTokenClaims?
    ) -> String? {
        if let name = profile?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }

        let profileParts = [profile?.firstName, profile?.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let profileJoined = profileParts.joined(separator: " ")
        if !profileJoined.isEmpty {
            return profileJoined
        }

        if let claimName = claims?.name?.trimmingCharacters(in: .whitespacesAndNewlines), !claimName.isEmpty {
            return claimName
        }

        let claimParts = [claims?.givenName, claims?.familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let claimJoined = claimParts.joined(separator: " ")
        return claimJoined.isEmpty ? nil : claimJoined
    }

    private static func mapPermission(_ permission: FacebookPermission) -> Permission {
        switch permission {
        case .publicProfile:
            return .publicProfile
        case .email:
            return .email
        }
    }
}
