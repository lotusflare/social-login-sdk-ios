import Foundation

protocol SocialLoginBackendServicing: Sendable {
    func fetchSocialNonce(
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<String, SocialLoginError>) -> Void
    )

    func loginWithProvider(
        payload: ProviderAuthPayload,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    )

    func refreshToken(
        _ refreshToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginTokenRefresh, SocialLoginError>) -> Void
    )

    func logout(
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func requestEmailSignUpCode(
        email: String,
        eventName: String?,
        language: String?,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func completeEmailSignUp(
        email: String,
        code: String,
        password: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailSignUpResult, SocialLoginError>) -> Void
    )

    func signInWithEmail(
        email: String,
        password: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    )

    func isEmailRegistered(
        email: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailRegistrationStatus, SocialLoginError>) -> Void
    )

    func requestPasswordResetCode(
        email: String,
        eventName: String?,
        language: String?,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func resetPassword(
        email: String,
        code: String,
        newPassword: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func requestPasswordChangeCode(
        eventName: String?,
        language: String?,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func changePasswordWithCurrent(
        currentPassword: String,
        newPassword: String,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )

    func changePasswordWithCode(
        code: String,
        newPassword: String,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    )
}
