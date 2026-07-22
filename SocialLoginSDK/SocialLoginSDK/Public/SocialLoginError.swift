import Foundation

public enum SocialLoginError: Error, Sendable {
    case notConfigured
    case missingProviderConfiguration(SocialLoginProvider)
    case missingBackendConfiguration(message: String)
    case cancelled
    case providerSignInFailed(SocialLoginProvider, message: String)
    case missingPresenter
    /// Transport / unknown-business-code / invalid envelope fallback for appauth HTTP.
    case backendRequestFailed(statusCode: Int?, code: Int?, message: String)
    case clientInvalid(message: String)
    case loginMethodNotAllowed(message: String)
    case userNotFound(message: String)
    case invalidPassword(message: String)
    case emailAlreadyRegistered(message: String)
    case registrationNotAllowed(message: String)
    case oauthTokenInvalid(String)
    case oauthEmailConflict(String)
    /// Gateway / IAM `40001`: access token expired or invalid; host should call `refreshToken`.
    case accessTokenInvalid(message: String)
    /// Appauth `44209`, or a missing / unusable refresh token on the client.
    case refreshTokenInvalid(message: String)
    case rateLimited(String)
    case emailCodeInvalid(message: String)
    case passwordPolicyViolation(message: String)
    case oauthNonceInvalid(String)
    case oauthAudienceMismatch(message: String)
}

extension SocialLoginError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "SocialLoginSDK is not configured. Call setup(...) at app launch."
        case .missingProviderConfiguration(let provider):
            switch provider {
            case .google:
                return "Google sign-in is not configured. Set googleClientID (and googleServerClientID for backend exchange)."
            case .facebook:
                return "Facebook sign-in is not configured. Set facebookAppID and facebookClientToken."
            case .apple:
                return "Apple sign-in is not configured."
            }
        case .missingBackendConfiguration(let message):
            return message
        case .cancelled:
            return "Sign-in was cancelled."
        case .providerSignInFailed(let provider, let message):
            return "\(provider.rawValue.capitalized) sign-in failed: \(message)"
        case .missingPresenter:
            return "A presenting view controller is required for sign-in."
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
        case .clientInvalid(let message):
            return message
        case .loginMethodNotAllowed(let message):
            return message
        case .userNotFound(let message):
            return message
        case .invalidPassword(let message):
            return message
        case .emailAlreadyRegistered(let message):
            return message
        case .registrationNotAllowed(let message):
            return message
        case .oauthTokenInvalid(let message):
            return message
        case .oauthEmailConflict(let message):
            return message
        case .accessTokenInvalid(let message):
            return message
        case .refreshTokenInvalid(let message):
            return message
        case .rateLimited(let message):
            return message
        case .emailCodeInvalid(let message):
            return message
        case .passwordPolicyViolation(let message):
            return message
        case .oauthNonceInvalid(let message):
            return message
        case .oauthAudienceMismatch(let message):
            return message
        }
    }
}
