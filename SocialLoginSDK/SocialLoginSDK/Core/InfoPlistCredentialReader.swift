import Foundation

enum InfoPlistCredentialKeys {
    static let googleClientID = "GIDClientID"
    static let googleServerClientID = "GIDServerClientID"
    static let facebookAppID = "FacebookAppID"
    static let facebookClientToken = "FacebookClientToken"

    static let stagingBaseURL = "SocialLoginStagingBaseURL"
    static let productionBaseURL = "SocialLoginProductionBaseURL"
    static let clientID = "SocialLoginClientID"
    static let stagingClientID = "SocialLoginStagingClientID"
    static let productionClientID = "SocialLoginProductionClientID"
}

enum InfoPlistCredentialReader {
    static func string(forKey key: String, bundle: Bundle = .main) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func backendConfiguration(
        for environment: SocialLoginEnvironment,
        bundle: Bundle = .main
    ) -> Result<BackendConfiguration, SocialLoginError> {
        let baseURLKey: String
        let environmentClientIDKey: String
        switch environment {
        case .staging:
            baseURLKey = InfoPlistCredentialKeys.stagingBaseURL
            environmentClientIDKey = InfoPlistCredentialKeys.stagingClientID
        case .production:
            baseURLKey = InfoPlistCredentialKeys.productionBaseURL
            environmentClientIDKey = InfoPlistCredentialKeys.productionClientID
        }

        guard let baseURLString = string(forKey: baseURLKey, bundle: bundle) else {
            return .failure(
                .missingBackendConfiguration(
                    message: "Missing Info.plist key '\(baseURLKey)' (or pass BackendConfiguration explicitly)."
                )
            )
        }

        guard let baseURL = URL(string: baseURLString) else {
            return .failure(
                .missingBackendConfiguration(
                    message: "Invalid URL for Info.plist key '\(baseURLKey)'."
                )
            )
        }

        guard let clientID = coalesce(
            string(forKey: environmentClientIDKey, bundle: bundle),
            string(forKey: InfoPlistCredentialKeys.clientID, bundle: bundle)
        ) else {
            return .failure(
                .missingBackendConfiguration(
                    message: "Missing Info.plist key '\(environmentClientIDKey)' or '\(InfoPlistCredentialKeys.clientID)' (or pass BackendConfiguration explicitly)."
                )
            )
        }

        return .success(BackendConfiguration(baseURL: baseURL, clientID: clientID))
    }

    private static func coalesce(_ preferred: String?, _ fallback: String?) -> String? {
        if let preferred, !preferred.isEmpty {
            return preferred
        }
        return fallback
    }
}

extension SocialLoginConfiguration {
    /// Fills missing Google / Facebook credentials from the host app Info.plist.
    /// Explicit `configure` values always win over plist entries.
    func resolvingProviderCredentials(from bundle: Bundle = .main) -> SocialLoginConfiguration {
        SocialLoginConfiguration(
            environment: environment,
            googleClientID: Self.coalesce(
                googleClientID,
                InfoPlistCredentialReader.string(forKey: InfoPlistCredentialKeys.googleClientID, bundle: bundle)
            ),
            googleServerClientID: Self.coalesce(
                googleServerClientID,
                InfoPlistCredentialReader.string(
                    forKey: InfoPlistCredentialKeys.googleServerClientID,
                    bundle: bundle
                )
            ),
            facebookAppID: Self.coalesce(
                facebookAppID,
                InfoPlistCredentialReader.string(forKey: InfoPlistCredentialKeys.facebookAppID, bundle: bundle)
            ),
            facebookClientToken: Self.coalesce(
                facebookClientToken,
                InfoPlistCredentialReader.string(
                    forKey: InfoPlistCredentialKeys.facebookClientToken,
                    bundle: bundle
                )
            ),
            facebook: facebook,
            apple: apple,
            backend: backend
        )
    }

    /// Fills missing backend configuration from Info.plist using environment-specific keys.
    /// Explicit `backend` always wins over plist entries.
    func resolvingBackend(from bundle: Bundle = .main) -> Result<SocialLoginConfiguration, SocialLoginError> {
        if let backend {
            return .success(
                SocialLoginConfiguration(
                    environment: environment,
                    googleClientID: googleClientID,
                    googleServerClientID: googleServerClientID,
                    facebookAppID: facebookAppID,
                    facebookClientToken: facebookClientToken,
                    facebook: facebook,
                    apple: apple,
                    backend: backend
                )
            )
        }

        switch InfoPlistCredentialReader.backendConfiguration(for: environment, bundle: bundle) {
        case .failure(let error):
            return .failure(error)
        case .success(let resolvedBackend):
            return .success(
                SocialLoginConfiguration(
                    environment: environment,
                    googleClientID: googleClientID,
                    googleServerClientID: googleServerClientID,
                    facebookAppID: facebookAppID,
                    facebookClientToken: facebookClientToken,
                    facebook: facebook,
                    apple: apple,
                    backend: resolvedBackend
                )
            )
        }
    }

    private static func coalesce(_ preferred: String?, _ fallback: String?) -> String? {
        if let preferred {
            let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return fallback
    }
}
