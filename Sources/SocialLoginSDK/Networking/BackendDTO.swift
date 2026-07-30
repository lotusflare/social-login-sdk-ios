import Foundation

protocol BackendCodedResponse {
    var code: Int? { get }
}

struct SocialNonceResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: SocialNonceData?

    struct SocialNonceData: Decodable, Sendable {
        let nonce: String
        let expiresIn: Int?
    }
}

struct SocialLoginRequest: Encodable, Sendable {
    let loginType: String
    let idToken: String
    let nonce: String
    let userName: String?
}

struct BackendLinkedProvider: Decodable, Sendable {
    let provider: String
    let providerUserId: String?
    let providerEmail: String?
    let providerFirstName: String?
    let providerLastName: String?
    let createdAt: Int64?
    let updatedAt: Int64?

    func toPublic() -> SocialLoginLinkedProvider {
        SocialLoginLinkedProvider(
            provider: provider,
            providerUserId: providerUserId,
            providerEmail: providerEmail,
            providerFirstName: providerFirstName,
            providerLastName: providerLastName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct BackendUserProfile: Decodable, Sendable {
    let userId: String
    let primaryEmail: String?
    let firstName: String?
    let lastName: String?
    let createdAt: Int64?
    let lastLoginAt: Int64?
    let updatedAt: Int64?
    let providers: [BackendLinkedProvider]?
}

struct BackendSessionResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: BackendSessionData?

    struct BackendSessionData: Decodable, Sendable {
        let accessToken: String?
        let refreshToken: String?
        let accessTokenExpin: Int?
        let refreshTokenExpin: Int?
        let isNewUser: Bool?
        let userProfile: BackendUserProfile?
    }
}

struct BackendRefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

struct BackendRefreshResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: BackendRefreshData?

    struct BackendRefreshData: Decodable, Sendable {
        let accessToken: String?
        let refreshToken: String?
        let accessTokenExpin: Int?
        let refreshTokenExpin: Int?
    }
}

struct BackendLogoutResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: BackendLogoutData?

    struct BackendLogoutData: Decodable, Sendable {
        let success: Bool?
    }
}

struct BackendErrorResponse: Decodable, Sendable {
    let code: Int?
    let message: String?
    let body: BodyPayload?

    struct BodyPayload: Decodable, Sendable {
        let resendAfterSec: Int?
        let lockRemainingSec: Int?
        let retryAfterSec: Int?
        let existsLoginTypes: [String]?
    }
}

struct EmailGetCodeRequest: Encodable, Sendable {
    let email: String
    let language: String?
}

struct EmailSignUpGetCodeResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: DataPayload?

    struct DataPayload: Decodable, Sendable {
        let email: String?
        let codeSent: Bool?
        let needEmailVerify: Bool?
        let resendAfterSec: Int?
        let lockRemainingSec: Int?
    }
}

struct EmailSignUpRequest: Encodable, Sendable {
    let email: String
    let code: String
    let password: String
}

struct EmailSignUpResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: DataPayload?

    struct DataPayload: Decodable, Sendable {
        let userId: String?
        let email: String?
        let registerCompleted: Bool?
    }
}

struct EmailSignInRequest: Encodable, Sendable {
    let email: String
    let password: String
}

struct EmailIsRegisteredRequest: Encodable, Sendable {
    let email: String
}

struct EmailIsRegisteredResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: DataPayload?

    struct DataPayload: Decodable, Sendable {
        let email: String?
        let registered: Bool?
        let existsLoginTypes: [String]?
    }
}

struct PasswordResetRequest: Encodable, Sendable {
    let email: String
    let code: String
    let newPassword: String
}

struct PasswordChangeWithCurrentRequest: Encodable, Sendable {
    let currentPassword: String
    let newPassword: String
}

struct PasswordChangeWithCodeRequest: Encodable, Sendable {
    let code: String
    let newPassword: String
}

struct PasswordChangeGetCodeRequest: Encodable, Sendable {
    let language: String?
}

struct PasswordOperationResponse: Decodable, Sendable, BackendCodedResponse {
    let code: Int?
    let data: DataPayload?

    struct DataPayload: Decodable, Sendable {
        let success: Bool?
        let resendAfterSec: Int?
        let lockRemainingSec: Int?
    }
}

/// Fixed appauth relative paths used by all SDK networking calls.
enum BackendAPIPath {
    // Social / session
    static let socialSignIn = "/auth/social/sign_in"
    static let socialNonce = "/auth/social/nonce"
    static let signOut = "/auth/sign_out"
    static let refreshToken = "/auth/refresh_token"

    // Email
    static let emailSignUpGetCode = "/auth/email/sign_up/get_code"
    static let emailSignUp = "/auth/email/sign_up"
    static let emailSignIn = "/auth/email/sign_in"
    static let emailIsRegistered = "/auth/email/is_registered"

    // Password
    static let passwordResetGetCode = "/auth/password/reset/get_code"
    static let passwordReset = "/auth/password/reset"
    static let passwordChange = "/auth/password/change"
    static let passwordChangeGetCode = "/auth/password/change/get_code"
}

/// Common appauth / IAM business codes.
enum BackendErrorCode: Int, Sendable {
    /// Access token expired or invalid (IAM / gateway).
    case accessTokenInvalid = 40001
    /// Request parameter validation failed (IAM / gateway).
    case invalidRequest = 40002
    case clientInvalid = 44201
    case loginMethodNotAllowed = 44202
    case userNotFound = 44203
    case invalidPassword = 44204
    case emailAlreadyRegistered = 44205
    case registrationNotAllowed = 44206
    case oauthTokenInvalid = 44207
    case oauthEmailConflict = 44208
    case refreshTokenInvalid = 44209
    case rateLimited = 44211
    case emailCodeInvalid = 44214
    case passwordPolicyViolation = 44219
    case oauthNonceInvalid = 44221
    case oauthAudienceMismatch = 44222
    case emailCodeExpired = 44223
    case emailCodeAlreadyUsed = 44224
}

enum TokenExpiry {
    static func date(fromExpiresIn seconds: Int?) -> Date? {
        guard let seconds, seconds > 0 else { return nil }
        return Date().addingTimeInterval(TimeInterval(seconds))
    }
}
