import Foundation

enum BackendErrorParser {
    static func parse(data: Data?, statusCode: Int?) -> SocialLoginError {
        if let data,
           let response = try? BackendJSONCoder.decoder.decode(BackendErrorResponse.self, from: data),
           let code = response.code {
            if let mapped = mapBusinessCode(code, message: response.message, body: response.body) {
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

    static func mapBusinessCode(
        _ code: Int,
        message: String?,
        body: BackendErrorResponse.BodyPayload?
    ) -> SocialLoginError? {
        let resolvedMessage = message ?? "Backend request failed."
        let loginTypes = (body?.existsLoginTypes ?? []).compactMap(SocialLoginLoginType.init(rawValue:))

        guard let businessCode = BackendErrorCode(rawValue: code) else {
            return nil
        }

        switch businessCode {
        case .accessTokenInvalid:
            return .accessTokenInvalid(message: resolvedMessage)
        case .invalidRequest:
            return .invalidRequest(message: resolvedMessage)
        case .clientInvalid:
            return .clientInvalid(message: resolvedMessage)
        case .loginMethodNotAllowed:
            return .loginMethodNotAllowed(message: resolvedMessage)
        case .userNotFound:
            return .userNotFound(message: resolvedMessage)
        case .invalidPassword:
            return .invalidPassword(message: resolvedMessage, existsLoginTypes: loginTypes)
        case .emailAlreadyRegistered:
            return .emailAlreadyRegistered(message: resolvedMessage, existsLoginTypes: loginTypes)
        case .registrationNotAllowed:
            return .registrationNotAllowed(message: resolvedMessage)
        case .oauthTokenInvalid:
            return .oauthTokenInvalid(resolvedMessage)
        case .oauthEmailConflict:
            return .oauthEmailConflict(resolvedMessage)
        case .refreshTokenInvalid:
            return .refreshTokenInvalid(message: resolvedMessage)
        case .rateLimited:
            return .rateLimited(
                message: resolvedMessage,
                resendAfterSec: body?.resendAfterSec,
                lockRemainingSec: body?.lockRemainingSec,
                retryAfterSec: body?.retryAfterSec
            )
        case .oauthNonceInvalid:
            return .oauthNonceInvalid(resolvedMessage)
        case .emailCodeInvalid:
            return .emailCodeInvalid(message: resolvedMessage)
        case .emailCodeExpired:
            return .emailCodeExpired(message: resolvedMessage)
        case .emailCodeAlreadyUsed:
            return .emailCodeAlreadyUsed(message: resolvedMessage)
        case .passwordPolicyViolation:
            return .passwordPolicyViolation(message: resolvedMessage)
        case .oauthAudienceMismatch:
            return .oauthAudienceMismatch(message: resolvedMessage)
        }
    }
}
