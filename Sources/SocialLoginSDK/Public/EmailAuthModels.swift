import Foundation

/// Login methods that can be bound to an email (`exists_login_types` / social `login_type`).
public enum SocialLoginLoginType: String, CaseIterable, Codable, Sendable {
    case email
    case google
    case apple
    case facebook
}

/// Result of `POST /auth/email/is_registered`.
public struct EmailRegistrationStatus: Sendable {
    /// Queried email (backend returns lowercase).
    public let email: String
    /// `true` if the email is already registered.
    public let registered: Bool
    /// Bound login methods when `registered` is `true` and bindings exist; otherwise empty.
    public let existsLoginTypes: [SocialLoginLoginType]

    public init(email: String, registered: Bool, existsLoginTypes: [SocialLoginLoginType] = []) {
        self.email = email
        self.registered = registered
        self.existsLoginTypes = existsLoginTypes
    }
}

/// Result of email sign-up completion (no tokens issued; host must call `signInWithEmail`).
public struct EmailSignUpResult: Sendable {
    public let userID: String
    public let email: String
    public let registerCompleted: Bool

    public init(userID: String, email: String, registerCompleted: Bool) {
        self.userID = userID
        self.email = email
        self.registerCompleted = registerCompleted
    }
}

/// Result of `*/get_code` (sign-up / password reset / password change).
public struct EmailCodeSendResult: Sendable {
    public let email: String?
    public let codeSent: Bool?
    public let needEmailVerify: Bool?
    public let success: Bool?
    /// Seconds until the next send is allowed (cooldown).
    public let resendAfterSec: Int?
    /// Seconds remaining on OTP / credential lock when present.
    public let lockRemainingSec: Int?

    public init(
        email: String? = nil,
        codeSent: Bool? = nil,
        needEmailVerify: Bool? = nil,
        success: Bool? = nil,
        resendAfterSec: Int? = nil,
        lockRemainingSec: Int? = nil
    ) {
        self.email = email
        self.codeSent = codeSent
        self.needEmailVerify = needEmailVerify
        self.success = success
        self.resendAfterSec = resendAfterSec
        self.lockRemainingSec = lockRemainingSec
    }
}

enum PasswordPolicy {
    /// AppAuth §6 local pre-check. Returns an error message when invalid.
    static func validationMessage(for password: String) -> String? {
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }
        guard password.range(of: "[a-z]", options: .regularExpression) != nil else {
            return "Password must include a lowercase letter."
        }
        guard password.range(of: "[A-Z]", options: .regularExpression) != nil else {
            return "Password must include an uppercase letter."
        }
        guard password.range(of: "[0-9]", options: .regularExpression) != nil else {
            return "Password must include a digit."
        }
        guard password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil else {
            return "Password must include a special character."
        }
        return nil
    }

    static func validate(_ password: String) -> SocialLoginError? {
        guard let message = validationMessage(for: password) else { return nil }
        return .passwordPolicyViolation(message: message)
    }
}
