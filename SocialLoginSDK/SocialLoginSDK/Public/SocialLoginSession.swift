import Foundation

/// Linked IdP / email binding from appauth `user_profile.providers`.
public struct SocialLoginLinkedProvider: Codable, Sendable, Equatable {
    public let provider: String
    public let providerUserId: String?
    public let providerEmail: String?
    public let providerFirstName: String?
    public let providerLastName: String?
    public let createdAt: Int64?
    public let updatedAt: Int64?

    public init(
        provider: String,
        providerUserId: String? = nil,
        providerEmail: String? = nil,
        providerFirstName: String? = nil,
        providerLastName: String? = nil,
        createdAt: Int64? = nil,
        updatedAt: Int64? = nil
    ) {
        self.provider = provider
        self.providerUserId = providerUserId
        self.providerEmail = providerEmail
        self.providerFirstName = providerFirstName
        self.providerLastName = providerLastName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Login session snapshot. Profile fields mirror appauth `user_profile` naming.
public struct SocialLoginSession: Sendable {
    public let environment: SocialLoginEnvironment
    /// `user_profile.user_id`
    public let userId: String
    /// `user_profile.primary_email`
    public let primaryEmail: String?
    /// `user_profile.first_name`
    public let firstName: String?
    /// `user_profile.last_name`
    public let lastName: String?
    public let accessToken: String?
    public let refreshToken: String?
    /// Absolute expiry time derived from `access_token_expin` at receipt.
    public let accessTokenExpiresAt: Date?
    /// Absolute expiry time derived from `refresh_token_expin` at receipt.
    public let refreshTokenExpiresAt: Date?
    /// Present only for social sign-in responses when the backend reports a silent registration.
    public let isNewUser: Bool?
    /// `user_profile.created_at`
    public let createdAt: Int64?
    /// `user_profile.last_login_at`
    public let lastLoginAt: Int64?
    /// `user_profile.updated_at`
    public let updatedAt: Int64?
    /// `user_profile.providers`
    public let providers: [SocialLoginLinkedProvider]?

    public init(
        environment: SocialLoginEnvironment,
        userId: String,
        primaryEmail: String?,
        firstName: String? = nil,
        lastName: String? = nil,
        accessToken: String?,
        refreshToken: String?,
        accessTokenExpiresAt: Date? = nil,
        refreshTokenExpiresAt: Date? = nil,
        isNewUser: Bool? = nil,
        createdAt: Int64? = nil,
        lastLoginAt: Int64? = nil,
        updatedAt: Int64? = nil,
        providers: [SocialLoginLinkedProvider]? = nil
    ) {
        self.environment = environment
        self.userId = userId
        self.primaryEmail = primaryEmail
        self.firstName = firstName
        self.lastName = lastName
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
        self.isNewUser = isNewUser
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.updatedAt = updatedAt
        self.providers = providers
    }

    public var isAccessTokenExpired: Bool {
        guard let accessTokenExpiresAt else { return false }
        return accessTokenExpiresAt <= Date()
    }

    /// Returns a copy with tokens / expiry from `refreshToken` API response.
    public func applying(_ tokenRefresh: SocialLoginTokenRefresh) -> SocialLoginSession {
        SocialLoginSession(
            environment: environment,
            userId: userId,
            primaryEmail: primaryEmail,
            firstName: firstName,
            lastName: lastName,
            accessToken: tokenRefresh.accessToken,
            refreshToken: tokenRefresh.refreshToken ?? refreshToken,
            accessTokenExpiresAt: tokenRefresh.accessTokenExpiresAt,
            refreshTokenExpiresAt: tokenRefresh.refreshTokenExpiresAt ?? refreshTokenExpiresAt,
            isNewUser: isNewUser,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            updatedAt: updatedAt,
            providers: providers
        )
    }
}

/// Tokens returned by `SocialLoginSDK.refreshToken` (`POST /auth/refresh_token`).
public struct SocialLoginTokenRefresh: Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let accessTokenExpiresAt: Date?
    public let refreshTokenExpiresAt: Date?

    public init(
        accessToken: String,
        refreshToken: String?,
        accessTokenExpiresAt: Date? = nil,
        refreshTokenExpiresAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accessTokenExpiresAt = accessTokenExpiresAt
        self.refreshTokenExpiresAt = refreshTokenExpiresAt
    }
}
