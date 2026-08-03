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
    /// Optional per-request timeout in seconds for appauth HTTP calls.
    /// When `nil`, the URLSession / system default timeout is used (typically 60s for
    /// `URLSession.shared`). Values below 1 are clamped to 1 when applied.
    public let requestTimeoutSeconds: Int?

    /// Creates a backend configuration for the official appauth gateway.
    /// Host apps typically only need `baseURL` and `clientID`. API paths are fixed in the SDK.
    public init(
        baseURL: URL,
        clientID: String,
        deviceID: String? = nil,
        additionalHeaders: [String: String] = [:],
        requestTimeoutSeconds: Int? = nil
    ) {
        self.baseURL = baseURL
        self.clientID = clientID
        self.deviceID = deviceID
        self.additionalHeaders = additionalHeaders
        self.requestTimeoutSeconds = requestTimeoutSeconds
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
    /// From Info.plist `GIDClientID` after `setup` resolves credentials.
    let googleClientID: String?
    /// From Info.plist `GIDServerClientID` after `setup` resolves credentials.
    let googleServerClientID: String?
    /// From Info.plist `FacebookAppID` after `setup` resolves credentials.
    let facebookAppID: String?
    /// From Info.plist `FacebookClientToken` after `setup` resolves credentials.
    let facebookClientToken: String?
    public let facebook: FacebookSignInConfiguration
    public let apple: AppleSignInConfiguration
    /// Optional. When omitted, the SDK reads environment-specific Base URL / Client ID from Info.plist.
    /// Every successful sign-in exchanges provider credentials for backend tokens.
    public let backend: BackendConfiguration?

    /// Google / Facebook client credentials are read only from Info.plist
    /// (`GIDClientID`, `GIDServerClientID`, `FacebookAppID`, `FacebookClientToken`).
    /// `backend` may be omitted when declared in Info.plist. `environment` is required.
    public init(
        environment: SocialLoginEnvironment,
        facebook: FacebookSignInConfiguration = FacebookSignInConfiguration(),
        apple: AppleSignInConfiguration = AppleSignInConfiguration(),
        backend: BackendConfiguration? = nil
    ) {
        self.environment = environment
        self.googleClientID = nil
        self.googleServerClientID = nil
        self.facebookAppID = nil
        self.facebookClientToken = nil
        self.facebook = facebook
        self.apple = apple
        self.backend = backend
    }

    init(
        environment: SocialLoginEnvironment,
        googleClientID: String?,
        googleServerClientID: String?,
        facebookAppID: String?,
        facebookClientToken: String?,
        facebook: FacebookSignInConfiguration,
        apple: AppleSignInConfiguration,
        backend: BackendConfiguration?
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
