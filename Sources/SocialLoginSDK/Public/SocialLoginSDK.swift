import FacebookCore
import Foundation
import UIKit

public enum SocialLoginSDK {
    private static let manager = SocialLoginManager()

    /// Configures backend / provider credentials only (no Facebook app lifecycle).
    /// Use from app extensions (e.g. Widget) that need networking such as `refreshToken`.
    /// Does not load or persist sessions — the host owns token storage.
    @discardableResult
    public static func configure(
        _ configuration: SocialLoginConfiguration
    ) -> SocialLoginError? {
        manager.configure(configuration)
    }

    /// Configures the SDK and initializes Facebook lifecycle hooks.
    /// Prefer this from the main app `application(_:didFinishLaunchingWithOptions:)`.
    /// Does not load or persist sessions — the host owns token storage.
    @discardableResult
    public static func setup(
        configuration: SocialLoginConfiguration,
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> SocialLoginError? {
        _ = ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return configure(configuration)
    }

    public static func isProviderConfigured(_ provider: SocialLoginProvider) -> Bool {
        manager.isProviderConfigured(provider)
    }

    public static func signIn(
        provider: SocialLoginProvider,
        from viewController: UIViewController,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        manager.signIn(provider: provider, from: viewController, completion: completion)
    }

    public static func refreshToken(
        _ refreshToken: String,
        completion: @escaping (Result<SocialLoginTokenRefresh, SocialLoginError>) -> Void
    ) {
        manager.refreshToken(refreshToken, completion: completion)
    }

    /// Signs out of the backend when `accessToken` is set, then clears all provider SDK sessions.
    /// Host must clear its own persisted tokens.
    public static func signOut(accessToken: String?) {
        manager.signOut(accessToken: accessToken)
    }

    @discardableResult
    public static func handleOpenURL(_ url: URL) -> Bool {
        manager.handleOpenURL(url)
    }

    // MARK: - Email auth (networking only; host builds UI)

    public static func requestEmailSignUpCode(
        email: String,
        language: String? = nil,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        manager.requestEmailSignUpCode(
            email: email,
            language: language,
            completion: completion
        )
    }

    public static func completeEmailSignUp(
        email: String,
        code: String,
        password: String,
        completion: @escaping (Result<EmailSignUpResult, SocialLoginError>) -> Void
    ) {
        manager.completeEmailSignUp(
            email: email,
            code: code,
            password: password,
            completion: completion
        )
    }

    public static func signInWithEmail(
        email: String,
        password: String,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        manager.signInWithEmail(email: email, password: password, completion: completion)
    }

    public static func isEmailRegistered(
        email: String,
        completion: @escaping (Result<EmailRegistrationStatus, SocialLoginError>) -> Void
    ) {
        manager.isEmailRegistered(email: email, completion: completion)
    }

    public static func requestPasswordResetCode(
        email: String,
        language: String? = nil,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        manager.requestPasswordResetCode(
            email: email,
            language: language,
            completion: completion
        )
    }

    public static func resetPassword(
        email: String,
        code: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        manager.resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
            completion: completion
        )
    }

    public static func requestPasswordChangeCode(
        accessToken: String,
        language: String? = nil,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        manager.requestPasswordChangeCode(
            accessToken: accessToken,
            language: language,
            completion: completion
        )
    }

    public static func changePassword(
        accessToken: String,
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        manager.changePasswordWithCurrent(
            accessToken: accessToken,
            currentPassword: currentPassword,
            newPassword: newPassword,
            completion: completion
        )
    }

    public static func changePassword(
        accessToken: String,
        code: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        manager.changePasswordWithCode(
            accessToken: accessToken,
            code: code,
            newPassword: newPassword,
            completion: completion
        )
    }
}
