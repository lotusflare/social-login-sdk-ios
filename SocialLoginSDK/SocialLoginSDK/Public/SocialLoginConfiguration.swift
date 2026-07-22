import Foundation

public struct BackendConfiguration: Sendable {
    /// Appauth gateway base URL. Prefer Info.plist keys (`SocialLoginStagingBaseURL` /
    /// `SocialLoginProductionBaseURL`) or pass explicitly to override.
    /// Examples: `https://rmax-dev.nomadsplits.com/appauth/` (Dev),
    /// `https://rmax.nomadsplits.com/appauth/` (Prod). Trailing slash recommended.
    public let baseURL: URL
    /// Business-line client identifier sent as the `X-Client-Id` request header.
    /// Prefer Info.plist `SocialLoginClientID` (or per-environment overrides) or pass explicitly.
    public let clientID: String
    public let deviceID: String?
    public let additionalHeaders: [String: String]

    /// Creates a backend configuration for the official appauth gateway.
    /// Host apps typically only need `baseURL` and `clientID`. API paths are fixed in the SDK.
    public init(
        baseURL: URL,
        clientID: String,
        deviceID: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.clientID = clientID
        self.deviceID = deviceID
        self.additionalHeaders = additionalHeaders
    }

    func resolvedDeviceID() -> String {
        deviceID ?? DeviceIdentifierProvider.currentDeviceID()
    }

    /// Joins `path` onto `baseURL`. Leading `/` on `path` is stripped so `/appauth/` is preserved.
    /// Example: base `…/appauth/` + `/auth/social/nonce` → `…/appauth/auth/social/nonce`.
    func makeURL(path: String) -> URL? {
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard !relativePath.isEmpty else { return baseURL.absoluteURL }
        return URL(string: relativePath, relativeTo: baseURL)?.absoluteURL
    }
}

public struct SocialLoginConfiguration: Sendable {
    public let environment: SocialLoginEnvironment
    /// Optional. When omitted, the SDK reads `GIDClientID` from the host Info.plist.
    public let googleClientID: String?
    /// Optional. When omitted, the SDK reads `GIDServerClientID` from the host Info.plist.
    /// Web client ID for Google ID token `aud` alignment with appauth.
    public let googleServerClientID: String?
    /// Optional. When omitted, the SDK reads `FacebookAppID` from the host Info.plist.
    public let facebookAppID: String?
    /// Optional. When omitted, the SDK reads `FacebookClientToken` from the host Info.plist.
    public let facebookClientToken: String?
    public let facebook: FacebookSignInConfiguration
    public let apple: AppleSignInConfiguration
    /// Optional. When omitted, the SDK reads environment-specific Base URL / Client ID from Info.plist.
    /// Every successful sign-in exchanges provider credentials for backend tokens.
    public let backend: BackendConfiguration?

    /// Provider credentials and backend may be omitted when declared in Info.plist.
    /// Explicit values passed here override Info.plist. `environment` is required.
    public init(
        environment: SocialLoginEnvironment,
        googleClientID: String? = nil,
        googleServerClientID: String? = nil,
        facebookAppID: String? = nil,
        facebookClientToken: String? = nil,
        facebook: FacebookSignInConfiguration = FacebookSignInConfiguration(),
        apple: AppleSignInConfiguration = AppleSignInConfiguration(),
        backend: BackendConfiguration? = nil
    ) {
        self.environment = environment
        self.googleClientID = googleClientID
        self.googleServerClientID = googleServerClientID
        self.facebookAppID = facebookAppID
        self.facebookClientToken = facebookClientToken
        self.facebook = facebook
        self.apple = apple
        self.backend = backend
    }
}
