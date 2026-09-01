import Foundation

public enum SocialLoginError: Error, Sendable {
    // MARK: - General

    case notConfigured
    case missingProviderConfiguration(SocialLoginProvider)
    case missingBackendConfiguration(message: String)
    case cancelled
    case missingPresenter
    /// Provider returned no ID token before the backend login request.
    case missingProviderIDToken(provider: SocialLoginProvider, message: String)

    // MARK: - Apple

    case appleSignInFailed(message: String)
    case appleUnexpectedCredentialType(message: String)

    // MARK: - Facebook

    /// Facebook Limited Login requires a social nonce from the backend.
    case missingSocialNonce(message: String)
    case invalidFacebookLoginConfiguration(message: String)
    case facebookSignInFailed(message: String)
    case missingFacebookAuthenticationToken(message: String)
    case facebookProfileLoadFailed(message: String)
    case missingFacebookUserIdentifier(message: String)

    // MARK: - Google

    case googleSignInFailed(message: String)
    case missingGoogleSignInResult(message: String)

    // MARK: - Backend transport

    /// Unknown business code / invalid envelope fallback for appauth HTTP.
    case backendRequestFailed(statusCode: Int?, code: Int?, message: String)
    /// Client-side HTTP request timed out (`URLError.timedOut`).
    case timeOut(message: String)
    /// Other `URLError` transport failures (offline, connection lost, DNS, etc.).
    case networkError(message: String)

    // MARK: - Backend business

    /// Gateway / IAM `40001`: access token expired or invalid; host should call `refreshToken`.
    case accessTokenInvalid(message: String)
    /// Gateway / IAM `40002`: request parameter validation failed.
    case invalidRequest(message: String)
    /// Appauth `44201`.
    case clientInvalid(message: String)
    /// Appauth `44202`.
    case loginMethodNotAllowed(message: String)
    /// Appauth `44203`.
    case userNotFound(message: String)
    /// Appauth `44204`.
    case invalidPassword(message: String, existsLoginTypes: [SocialLoginLoginType] = [])
    /// Appauth `44205`.
    case emailAlreadyRegistered(message: String, existsLoginTypes: [SocialLoginLoginType] = [])
    /// Appauth `44206`.
    case registrationNotAllowed(message: String)
    /// Appauth `44207`.
    case oauthTokenInvalid(String)
    /// Appauth `44208`.
    case oauthEmailConflict(String)
    /// Appauth `44209`, or a missing / unusable refresh token on the client.
    case refreshTokenInvalid(message: String)
    /// Appauth `44211`. Timing fields come from error `data` when present.
    case rateLimited(
        message: String,
        resendAfterSec: Int? = nil,
        lockRemainingSec: Int? = nil,
        retryAfterSec: Int? = nil
    )
    /// Appauth `44214`.
    case emailCodeInvalid(message: String)
    /// Appauth `44219`.
    case passwordPolicyViolation(message: String)
    /// Appauth `44221`. May also be raised client-side (e.g. Google ID token nonce mismatch).
    case oauthNonceInvalid(String)
    /// Appauth `44222`.
    case oauthAudienceMismatch(message: String)
    /// Appauth `44223`: email verification code expired.
    case emailCodeExpired(message: String)
    /// Appauth `44224`: email verification code already used.
    case emailCodeAlreadyUsed(message: String)
    /// Appauth `44226`: account created but auto-login token issuance failed.
    /// Hosts should navigate like `emailAlreadyRegistered` (prompt sign-in).
    case registrationAutoLoginFailed(message: String, existsLoginTypes: [SocialLoginLoginType] = [])
    /// Appauth `44227`: pure social account (no email-password binding) cannot
    /// change password or request password-reset / password-change codes.
    case socialAccountPasswordNotAllowed(message: String)
}

extension SocialLoginError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "SocialLoginSDK is not configured. Call setup(...) at app launch."
        case .missingProviderConfiguration(let provider):
            switch provider {
            case .google:
                return "Google sign-in is not configured. Set GIDClientID and GIDServerClientID in Info.plist."
            case .facebook:
                return "Facebook sign-in is not configured. Set FacebookAppID and FacebookClientToken in Info.plist."
            case .apple:
                return "Apple sign-in is not configured."
            }
        case .missingBackendConfiguration(let message):
            return message
        case .cancelled:
            return "Sign-in was cancelled."
        case .missingPresenter:
            return "A presenting view controller is required for sign-in."
        case .missingProviderIDToken(let provider, let message):
            return "\(provider.rawValue.capitalized) sign-in failed: \(message)"

        case .appleSignInFailed(let message):
            return "Apple sign-in failed: \(message)"
        case .appleUnexpectedCredentialType(let message):
            return message

        case .missingSocialNonce(let message):
            return message
        case .invalidFacebookLoginConfiguration(let message):
            return message
        case .facebookSignInFailed(let message):
            return "Facebook sign-in failed: \(message)"
        case .missingFacebookAuthenticationToken(let message):
            return message
        case .facebookProfileLoadFailed(let message):
            return "Failed to load Facebook profile: \(message)"
        case .missingFacebookUserIdentifier(let message):
            return message

        case .googleSignInFailed(let message):
            return "Google sign-in failed: \(message)"
        case .missingGoogleSignInResult(let message):
            return message

        case .backendRequestFailed(let statusCode, let code, let message):
            var parts: [String] = []
            if let statusCode {
                parts.append("HTTP \(statusCode)")
            }
            if let code {
                parts.append("code \(code)")
            }
            if parts.isEmpty {
                return "Backend request failed: \(message)"
            }
            return "Backend request failed (\(parts.joined(separator: ", "))): \(message)"
        case .timeOut(let message):
            return message
        case .networkError(let message):
            return message

        case .accessTokenInvalid(let message):
            return message
        case .invalidRequest(let message):
            return message
        case .clientInvalid(let message):
            return message
        case .loginMethodNotAllowed(let message):
            return message
        case .userNotFound(let message):
            return message
        case .invalidPassword(let message, _):
            return message
        case .emailAlreadyRegistered(let message, _):
            return message
        case .registrationNotAllowed(let message):
            return message
        case .oauthTokenInvalid(let message):
            return message
        case .oauthEmailConflict(let message):
            return message
        case .refreshTokenInvalid(let message):
            return message
        case .rateLimited(let message, _, _, _):
            return message
        case .emailCodeInvalid(let message):
            return message
        case .passwordPolicyViolation(let message):
            return message
        case .oauthNonceInvalid(let message):
            return message
        case .oauthAudienceMismatch(let message):
            return message
        case .emailCodeExpired(let message):
            return message
        case .emailCodeAlreadyUsed(let message):
            return message
        case .registrationAutoLoginFailed(let message, _):
            return message
        case .socialAccountPasswordNotAllowed(let message):
            return message
        }
    }
}
