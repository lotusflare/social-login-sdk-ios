import Foundation
import GoogleSignIn
import UIKit

final class GoogleLoginProvider: SocialLoginProviderType {
    private var configuration: SocialLoginConfiguration?

    func configure(with configuration: SocialLoginConfiguration) {
        self.configuration = configuration
        guard let googleClientID = configuration.googleClientID, !googleClientID.isEmpty else {
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: googleClientID,
            serverClientID: configuration.googleServerClientID
        )
    }

    func signIn(
        from viewController: UIViewController,
        rawNonce: String,
        completion: @escaping (Result<ProviderAuthPayload, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }

        guard let googleClientID = configuration.googleClientID, !googleClientID.isEmpty else {
            completion(.failure(.missingProviderConfiguration(.google)))
            return
        }

        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                clientID: googleClientID,
                serverClientID: configuration.googleServerClientID
            )
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: viewController,
            hint: nil,
            additionalScopes: [],
            nonce: rawNonce
        ) { result, error in
            if let error {
                completion(.failure(Self.mapError(error)))
                return
            }

            guard let result else {
                completion(.failure(.providerSignInFailed(.google, message: "Missing sign-in result.")))
                return
            }

            if let idToken = result.user.idToken?.tokenString {
                if !Self.validateNonce(idToken: idToken, expectedNonce: rawNonce) {
                    completion(.failure(.oauthNonceInvalid("Google ID token nonce mismatch.")))
                    return
                }
            }

            completion(.success(Self.makePayload(from: result.user, rawNonce: rawNonce)))
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    func handleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    private static func makePayload(from user: GIDGoogleUser, rawNonce: String) -> ProviderAuthPayload {
        ProviderAuthPayload(
            provider: .google,
            userID: user.userID ?? "",
            email: user.profile?.email,
            idToken: user.idToken?.tokenString,
            nonce: rawNonce
        )
    }

    private static func validateNonce(idToken: String, expectedNonce: String) -> Bool {
        guard let payload = decodeJWTPayload(idToken),
              let tokenNonce = payload["nonce"] as? String else {
            return false
        }
        return tokenNonce == expectedNonce
    }

    private static func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }

    private static func mapError(_ error: Error) -> SocialLoginError {
        let nsError = error as NSError
        if nsError.domain == kGIDSignInErrorDomain,
           nsError.code == GIDSignInError.canceled.rawValue {
            return .cancelled
        }
        return .providerSignInFailed(.google, message: error.localizedDescription)
    }
}
