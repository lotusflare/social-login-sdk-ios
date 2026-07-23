import Foundation

enum BackendErrorParser {
    static func parse(data: Data?, statusCode: Int?) -> SocialLoginError {
        if let data,
           let response = try? BackendJSONCoder.decoder.decode(BackendErrorResponse.self, from: data),
           let code = response.code {
            if let mapped = mapBusinessCode(code, message: response.message) {
                return mapped
            }
            return .backendRequestFailed(
                statusCode: statusCode,
                code: code,
                message: response.message ?? "Backend request failed."
            )
        }

        let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown backend error."
        return .backendRequestFailed(statusCode: statusCode, code: nil, message: message)
    }

    static func mapBusinessCode(_ code: Int, message: String?) -> SocialLoginError? {
        let resolvedMessage = message ?? "Backend request failed."

        guard let businessCode = BackendErrorCode(rawValue: code) else {
            return nil
        }

        switch businessCode {
        case .accessTokenInvalid:
            return .accessTokenInvalid(message: resolvedMessage)
        case .clientInvalid:
            return .clientInvalid(message: resolvedMessage)
        case .loginMethodNotAllowed:
            return .loginMethodNotAllowed(message: resolvedMessage)
        case .userNotFound:
            return .userNotFound(message: resolvedMessage)
        case .invalidPassword:
            return .invalidPassword(message: resolvedMessage)
        case .emailAlreadyRegistered:
            return .emailAlreadyRegistered(message: resolvedMessage)
        case .registrationNotAllowed:
            return .registrationNotAllowed(message: resolvedMessage)
        case .oauthTokenInvalid:
            return .oauthTokenInvalid(resolvedMessage)
        case .oauthEmailConflict:
            return .oauthEmailConflict(resolvedMessage)
        case .refreshTokenInvalid:
            return .refreshTokenInvalid(message: resolvedMessage)
        case .rateLimited:
            return .rateLimited(resolvedMessage)
        case .oauthNonceInvalid:
            return .oauthNonceInvalid(resolvedMessage)
        case .emailCodeInvalid:
            return .emailCodeInvalid(message: resolvedMessage)
        case .passwordPolicyViolation:
            return .passwordPolicyViolation(message: resolvedMessage)
        case .oauthAudienceMismatch:
            return .oauthAudienceMismatch(message: resolvedMessage)
        }
    }
}
