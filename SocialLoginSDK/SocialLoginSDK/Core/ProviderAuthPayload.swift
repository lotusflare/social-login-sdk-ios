import Foundation

/// Bridge model from provider sign-in to backend social login.
struct ProviderAuthPayload: Sendable {
    let provider: SocialLoginProvider
    let userID: String
    let email: String?
    let idToken: String?
    let nonce: String?
    let userName: String?

    init(
        provider: SocialLoginProvider,
        userID: String,
        email: String?,
        idToken: String?,
        nonce: String? = nil,
        userName: String? = nil
    ) {
        self.provider = provider
        self.userID = userID
        self.email = email
        self.idToken = idToken
        self.nonce = nonce
        self.userName = userName
    }
}
