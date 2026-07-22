import Foundation

enum BackendSessionMapper {
    static func makeSession(
        from data: BackendSessionResponse.BackendSessionData,
        environment: SocialLoginEnvironment
    ) -> SocialLoginSession? {
        guard let profile = data.userProfile else { return nil }
        let access = data.accessToken
        guard let access, !access.isEmpty else { return nil }

        return SocialLoginSession(
            environment: environment,
            userId: profile.userId,
            primaryEmail: profile.primaryEmail,
            firstName: profile.firstName,
            lastName: profile.lastName,
            accessToken: access,
            refreshToken: data.refreshToken,
            accessTokenExpiresAt: TokenExpiry.date(fromExpiresIn: data.accessTokenExpin),
            refreshTokenExpiresAt: TokenExpiry.date(fromExpiresIn: data.refreshTokenExpin),
            isNewUser: data.isNewUser,
            createdAt: profile.createdAt,
            lastLoginAt: profile.lastLoginAt,
            updatedAt: profile.updatedAt,
            providers: profile.providers?.map { $0.toPublic() }
        )
    }

    static func makeTokenRefresh(
        from data: BackendRefreshResponse.BackendRefreshData
    ) -> SocialLoginTokenRefresh? {
        guard let access = data.accessToken, !access.isEmpty else { return nil }
        return SocialLoginTokenRefresh(
            accessToken: access,
            refreshToken: data.refreshToken,
            accessTokenExpiresAt: TokenExpiry.date(fromExpiresIn: data.accessTokenExpin),
            refreshTokenExpiresAt: TokenExpiry.date(fromExpiresIn: data.refreshTokenExpin)
        )
    }
}
