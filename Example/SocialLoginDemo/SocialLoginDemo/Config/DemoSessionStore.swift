import Foundation
import SocialLoginSDK

/// Demo-only session persistence. Host apps should use their own secure store (Keychain, etc.).
enum DemoSessionStore {
    private static let defaultsKey = "demo.socialLogin.session.v2"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func save(_ session: SocialLoginSession) {
        guard let snapshot = Snapshot(session: session),
              let data = try? encoder.encode(snapshot) else {
            return
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func load() -> SocialLoginSession? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snapshot = try? decoder.decode(Snapshot.self, from: data) else {
            return nil
        }
        return snapshot.makeSession()
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}

private struct Snapshot: Codable {
    let environment: SocialLoginEnvironment
    let userId: String
    let primaryEmail: String?
    let firstName: String?
    let lastName: String?
    let accessToken: String
    let refreshToken: String?
    let accessTokenExpiresAt: Date?
    let refreshTokenExpiresAt: Date?
    let isNewUser: Bool?
    let createdAt: Int64?
    let lastLoginAt: Int64?
    let updatedAt: Int64?
    let providers: [SocialLoginLinkedProvider]?

    init?(session: SocialLoginSession) {
        guard let accessToken = session.accessToken, !accessToken.isEmpty else {
            return nil
        }
        self.environment = session.environment
        self.userId = session.userId
        self.primaryEmail = session.primaryEmail
        self.firstName = session.firstName
        self.lastName = session.lastName
        self.accessToken = accessToken
        self.refreshToken = session.refreshToken
        self.accessTokenExpiresAt = session.accessTokenExpiresAt
        self.refreshTokenExpiresAt = session.refreshTokenExpiresAt
        self.isNewUser = session.isNewUser
        self.createdAt = session.createdAt
        self.lastLoginAt = session.lastLoginAt
        self.updatedAt = session.updatedAt
        self.providers = session.providers
    }

    func makeSession() -> SocialLoginSession {
        SocialLoginSession(
            environment: environment,
            userId: userId,
            primaryEmail: primaryEmail,
            firstName: firstName,
            lastName: lastName,
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshTokenExpiresAt: refreshTokenExpiresAt,
            isNewUser: isNewUser,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            updatedAt: updatedAt,
            providers: providers
        )
    }
}
