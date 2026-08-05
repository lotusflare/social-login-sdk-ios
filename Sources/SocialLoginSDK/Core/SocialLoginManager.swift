import Foundation
import GoogleSignIn
import UIKit

final class SocialLoginManager {
    private var configuration: SocialLoginConfiguration?
    private let backendClient: SocialLoginBackendServicing
    private let googleProvider = GoogleLoginProvider()
    private let facebookProvider = FacebookLoginProvider()
    private let appleProvider = AppleLoginProvider()

    init(backendClient: SocialLoginBackendServicing = SocialLoginBackendClient()) {
        self.backendClient = backendClient
    }

    @discardableResult
    func configure(_ configuration: SocialLoginConfiguration) -> SocialLoginError? {
        let withProviders = configuration.resolvingProviderCredentials()
        switch withProviders.resolvingBackend() {
        case .failure(let error):
            self.configuration = nil
            return error
        case .success(let resolved):
            self.configuration = resolved
            googleProvider.configure(with: resolved)
            facebookProvider.configure(with: resolved)
            appleProvider.configure(with: resolved)
            return nil
        }
    }

    func isProviderConfigured(_ provider: SocialLoginProvider) -> Bool {
        guard let configuration else { return false }

        switch provider {
        case .google:
            let clientID = configuration.googleClientID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let serverClientID = configuration.googleServerClientID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !clientID.isEmpty && !serverClientID.isEmpty
        case .facebook:
            let appID = configuration.facebookAppID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let clientToken = configuration.facebookClientToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !appID.isEmpty && !clientToken.isEmpty
        case .apple:
            return true
        }
    }

    func signIn(
        provider: SocialLoginProvider,
        from viewController: UIViewController,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }

        backendClient.fetchSocialNonce(configuration: configuration) { [weak self] nonceResult in
            guard let self else { return }

            switch nonceResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let rawNonce):
                self.performProviderSignIn(
                    provider: provider,
                    rawNonce: rawNonce,
                    from: viewController,
                    configuration: configuration,
                    completion: completion
                )
            }
        }
    }

    func refreshToken(
        _ refreshToken: String,
        completion: @escaping (Result<SocialLoginTokenRefresh, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }

        backendClient.refreshToken(
            refreshToken,
            configuration: configuration,
            completion: completion
        )
    }

    /// Calls backend sign-out when `accessToken` is present, then clears provider SDK sessions.
    /// Does not manage host-owned token storage.
    func signOut(accessToken: String?) {
        let clearProviders = { [weak self] in
            self?.clearProviderSessions()
        }

        guard let configuration,
              let accessToken,
              !accessToken.isEmpty else {
            clearProviders()
            return
        }

        backendClient.logout(
            accessToken: accessToken,
            configuration: configuration
        ) { _ in
            clearProviders()
        }
    }

    func handleOpenURL(_ url: URL) -> Bool {
        if googleProvider.handleOpenURL(url) {
            return true
        }
        if facebookProvider.handleOpenURL(url) {
            return true
        }
        return appleProvider.handleOpenURL(url)
    }

    // MARK: - Email

    func requestEmailSignUpCode(
        email: String,
        language: String?,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.requestEmailSignUpCode(
            email: email,
            language: language,
            configuration: configuration,
            completion: completion
        )
    }

    func completeEmailSignUp(
        email: String,
        code: String,
        password: String,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.completeEmailSignUp(
            email: email,
            code: code,
            password: password,
            configuration: configuration,
            completion: completion
        )
    }

    func checkEmailCode(
        purpose: EmailCodeCheckPurpose,
        code: String,
        email: String?,
        accessToken: String?,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.checkEmailCode(
            purpose: purpose,
            code: code,
            email: email,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    func signInWithEmail(
        email: String,
        password: String,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.signInWithEmail(
            email: email,
            password: password,
            configuration: configuration,
            completion: completion
        )
    }

    func isEmailRegistered(
        email: String,
        completion: @escaping (Result<EmailRegistrationStatus, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.isEmailRegistered(
            email: email,
            configuration: configuration,
            completion: completion
        )
    }

    func requestPasswordResetCode(
        email: String,
        language: String?,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.requestPasswordResetCode(
            email: email,
            language: language,
            configuration: configuration,
            completion: completion
        )
    }

    func resetPassword(
        email: String,
        code: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        backendClient.resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
            configuration: configuration,
            completion: completion
        )
    }

    func requestPasswordChangeCode(
        accessToken: String,
        language: String?,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        guard !accessToken.isEmpty else {
            completion(.failure(.userNotFound(message: "Missing access token.")))
            return
        }
        backendClient.requestPasswordChangeCode(
            language: language,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    func changePasswordWithCurrent(
        accessToken: String,
        currentPassword: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        guard !accessToken.isEmpty else {
            completion(.failure(.userNotFound(message: "Missing access token.")))
            return
        }
        backendClient.changePasswordWithCurrent(
            currentPassword: currentPassword,
            newPassword: newPassword,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    func changePasswordWithCode(
        accessToken: String,
        code: String,
        newPassword: String,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        guard let configuration else {
            completion(.failure(.notConfigured))
            return
        }
        guard !accessToken.isEmpty else {
            completion(.failure(.userNotFound(message: "Missing access token.")))
            return
        }
        backendClient.changePasswordWithCode(
            code: code,
            newPassword: newPassword,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    // MARK: - Private

    private func performProviderSignIn(
        provider: SocialLoginProvider,
        rawNonce: String,
        from viewController: UIViewController,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        providerInstance(for: provider).signIn(
            from: viewController,
            rawNonce: rawNonce
        ) { [weak self] result in
            guard let self else { return }
            let continueLogin = {
                self.loginWithProviderResult(result, configuration: configuration, completion: completion)
            }
            if Thread.isMainThread {
                continueLogin()
            } else {
                DispatchQueue.main.async(execute: continueLogin)
            }
        }
    }

    private func loginWithProviderResult(
        _ result: Result<ProviderAuthPayload, SocialLoginError>,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        switch result {
        case .failure(let error):
            completion(.failure(error))
        case .success(let payload):
            backendClient.loginWithProvider(
                payload: payload,
                configuration: configuration,
                completion: completion
            )
        }
    }

    private func clearProviderSessions() {
        googleProvider.signOut()
        facebookProvider.signOut()
        appleProvider.signOut()
    }

    private func providerInstance(for provider: SocialLoginProvider) -> SocialLoginProviderType {
        switch provider {
        case .google:
            return googleProvider
        case .facebook:
            return facebookProvider
        case .apple:
            return appleProvider
        }
    }
}
