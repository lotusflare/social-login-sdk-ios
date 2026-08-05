import Combine
import Foundation
import SocialLoginSDK

@MainActor
final class DemoEmailAuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var code = ""
    @Published var newPassword = ""
    @Published var currentPassword = ""
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRegistered: Bool?
    @Published var existsLoginTypes: [SocialLoginLoginType] = []
    @Published var sessionHint: String?

    func reloadSessionHint() {
        if let session = DemoSessionStore.load() {
            let identity = session.primaryEmail ?? session.userId
            sessionHint = "Local session: \(identity) (\(session.environment.rawValue))"
        } else {
            sessionHint = "Local session: none — sign in first for refresh / sign_out."
        }
    }

    func checkRegistered() {
        run {
            SocialLoginSDK.isEmailRegistered(email: email) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { status in
                        self?.isRegistered = status.registered
                        self?.existsLoginTypes = status.existsLoginTypes
                        if status.registered {
                            let types = status.existsLoginTypes.map(\.rawValue).joined(separator: ", ")
                            self?.statusMessage = types.isEmpty
                                ? "Email is registered."
                                : "Email is registered. Login types: \(types)."
                        } else {
                            self?.statusMessage = "Email is available."
                        }
                    }
                }
            }
        }
    }

    func requestSignUpCode() {
        run {
            SocialLoginSDK.requestEmailSignUpCode(email: email, language: "en-US") { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { send in
                        self?.statusMessage = Self.codeSendStatus("Sign-up code sent", send)
                    }
                }
            }
        }
    }

    func completeSignUp() {
        run {
            SocialLoginSDK.completeEmailSignUp(email: email, code: code, password: password) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { session in
                        DemoSessionStore.save(session)
                        self?.reloadSessionHint()
                        self?.statusMessage =
                            "Signed up and signed in as \(session.primaryEmail ?? session.userId)."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    func checkSignUpCode() {
        run {
            SocialLoginSDK.checkEmailCode(
                purpose: .signUp,
                code: code,
                email: email
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        self?.statusMessage = "Sign-up code matched (not consumed). Complete sign-up next."
                    }
                }
            }
        }
    }

    func checkPasswordResetCode() {
        run {
            SocialLoginSDK.checkEmailCode(
                purpose: .passwordReset,
                code: code,
                email: email
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        self?.statusMessage = "Reset code matched (not consumed). Reset password next."
                    }
                }
            }
        }
    }

    func checkPasswordChangeCode() {
        guard let accessToken = DemoSessionStore.load()?.accessToken, !accessToken.isEmpty else {
            errorMessage = "Sign in first (need access token)."
            return
        }

        run {
            SocialLoginSDK.checkEmailCode(
                purpose: .passwordChange,
                code: code,
                accessToken: accessToken
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        self?.statusMessage = "Change-password code matched (not consumed)."
                    }
                }
            }
        }
    }

    func signIn() {
        run {
            SocialLoginSDK.signInWithEmail(email: email, password: password) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { session in
                        DemoSessionStore.save(session)
                        self?.reloadSessionHint()
                        self?.statusMessage = "Signed in as \(session.primaryEmail ?? session.userId)."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    func refreshSession() {
        guard let refreshToken = DemoSessionStore.load()?.refreshToken, !refreshToken.isEmpty else {
            errorMessage = "Sign in first (need refresh token)."
            return
        }

        run {
            SocialLoginSDK.refreshToken(refreshToken) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { tokens in
                        if let current = DemoSessionStore.load() {
                            DemoSessionStore.save(current.applying(tokens))
                        }
                        self?.reloadSessionHint()
                        self?.statusMessage = "Token refreshed (POST /auth/refresh_token)."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    func signOut() {
        let accessToken = DemoSessionStore.load()?.accessToken
        run {
            SocialLoginSDK.signOut(accessToken: accessToken)
            DemoSessionStore.clear()
            isLoading = false
            reloadSessionHint()
            statusMessage = "Signed out (POST /auth/sign_out when token present)."
            NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
        }
    }

    func requestResetCode() {
        run {
            SocialLoginSDK.requestPasswordResetCode(email: email, language: "en-US") { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { send in
                        self?.statusMessage = Self.codeSendStatus("Reset code sent", send)
                    }
                }
            }
        }
    }

    func resetPassword() {
        run {
            SocialLoginSDK.resetPassword(email: email, code: code, newPassword: newPassword) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        DemoSessionStore.clear()
                        self?.reloadSessionHint()
                        self?.statusMessage = "Password reset. Local session cleared; sign in again."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    func requestChangeCode() {
        guard let accessToken = DemoSessionStore.load()?.accessToken, !accessToken.isEmpty else {
            errorMessage = "Sign in first (need access token)."
            return
        }

        run {
            SocialLoginSDK.requestPasswordChangeCode(
                accessToken: accessToken,
                language: "en-US"
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) { send in
                        self?.statusMessage = Self.codeSendStatus("Change-password code sent", send)
                    }
                }
            }
        }
    }

    func changePasswordWithCurrent() {
        guard let accessToken = DemoSessionStore.load()?.accessToken, !accessToken.isEmpty else {
            errorMessage = "Sign in first (need access token)."
            return
        }

        run {
            SocialLoginSDK.changePassword(
                accessToken: accessToken,
                currentPassword: currentPassword,
                newPassword: newPassword
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        DemoSessionStore.clear()
                        self?.reloadSessionHint()
                        self?.statusMessage = "Password changed. Local session cleared."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    func changePasswordWithCode() {
        guard let accessToken = DemoSessionStore.load()?.accessToken, !accessToken.isEmpty else {
            errorMessage = "Sign in first (need access token)."
            return
        }

        run {
            SocialLoginSDK.changePassword(
                accessToken: accessToken,
                code: code,
                newPassword: newPassword
            ) { [weak self] result in
                Task { @MainActor in
                    self?.finish(result) {
                        DemoSessionStore.clear()
                        self?.reloadSessionHint()
                        self?.statusMessage = "Password changed via code. Local session cleared."
                        NotificationCenter.default.post(name: .demoSessionDidChange, object: nil)
                    }
                }
            }
        }
    }

    private func run(_ work: () -> Void) {
        isLoading = true
        errorMessage = nil
        statusMessage = nil
        work()
    }

    private static func codeSendStatus(_ prefix: String, _ send: EmailCodeSendResult) -> String {
        var parts = [prefix]
        if let resend = send.resendAfterSec {
            parts.append("resend_after_sec=\(resend)")
        }
        if let lock = send.lockRemainingSec {
            parts.append("lock_remaining_sec=\(lock)")
        }
        return parts.joined(separator: ". ") + "."
    }

    private func finish<T>(_ result: Result<T, SocialLoginError>, onSuccess: (T) -> Void) {
        isLoading = false
        switch result {
        case .success(let value):
            errorMessage = nil
            onSuccess(value)
        case .failure(let error):
            errorMessage = Self.describe(error)
        }
    }

    private static func describe(_ error: SocialLoginError) -> String {
        switch error {
        case .rateLimited(let message, let resendAfterSec, let lockRemainingSec, let retryAfterSec):
            var parts = [message]
            if let resendAfterSec {
                parts.append("resend_after_sec=\(resendAfterSec)")
            }
            if let lockRemainingSec {
                parts.append("lock_remaining_sec=\(lockRemainingSec)")
            }
            if let retryAfterSec {
                parts.append("retry_after_sec=\(retryAfterSec)")
            }
            return parts.joined(separator: " | ")
        case .emailAlreadyRegistered(let message, let types),
             .registrationAutoLoginFailed(let message, let types),
             .invalidPassword(let message, let types):
            if types.isEmpty {
                return message
            }
            return "\(message) (exists_login_types: \(types.map(\.rawValue).joined(separator: ", ")))"
        default:
            return error.localizedDescription
        }
    }

    private func finish(_ result: Result<Void, SocialLoginError>, onSuccess: () -> Void) {
        finish(result.map { _ in () }) { _ in onSuccess() }
    }
}

extension Notification.Name {
    static let demoSessionDidChange = Notification.Name("demoSessionDidChange")
}
