import AuthenticationServices
import Foundation
import UIKit

final class AppleLoginProvider: SocialLoginProviderType {
    private var configuration: SocialLoginConfiguration?
    private var coordinator: AppleSignInCoordinator?

    func configure(with configuration: SocialLoginConfiguration) {
        self.configuration = configuration
    }

    /// - Parameter rawNonce: Plaintext nonce from appauth. SDK hashes it for Apple and keeps raw in payload.
    func signIn(
        from viewController: UIViewController,
        rawNonce: String,
        completion: @escaping (Result<ProviderAuthPayload, SocialLoginError>) -> Void
    ) {
        guard configuration != nil else {
            completion(.failure(.notConfigured))
            return
        }

        let appleConfiguration = configuration?.apple ?? AppleSignInConfiguration()
        let coordinator = AppleSignInCoordinator()
        self.coordinator = coordinator

        let hashedNonce = NonceHasher.sha256Hex(rawNonce)
        coordinator.start(
            scopes: appleConfiguration.requestedScopes,
            hashedNonce: hashedNonce,
            presenting: viewController
        ) { [weak self] result in
            defer { self?.coordinator = nil }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let credential):
                completion(.success(Self.makePayload(from: credential, rawNonce: rawNonce)))
            }
        }
    }

    func signOut() {
        // Apple Sign In does not maintain a provider-side session to clear.
        // To fully disconnect Apple-side association, the user must revoke access in
        // Settings → Apple ID → Sign in with Apple.
    }

    func handleOpenURL(_ url: URL) -> Bool {
        _ = url
        return false
    }

    private static func makePayload(
        from credential: ASAuthorizationAppleIDCredential,
        rawNonce: String
    ) -> ProviderAuthPayload {
        let identityToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
        let userName = formattedName(from: credential.fullName)

        return ProviderAuthPayload(
            provider: .apple,
            userID: credential.user,
            email: credential.email,
            idToken: identityToken,
            nonce: rawNonce,
            userName: userName
        )
    }

    private static func formattedName(from personName: PersonNameComponents?) -> String? {
        guard let personName else { return nil }

        let formatter = PersonNameComponentsFormatter()
        let formatted = formatter.string(from: personName)
        return formatted.isEmpty ? nil : formatted
    }
}
