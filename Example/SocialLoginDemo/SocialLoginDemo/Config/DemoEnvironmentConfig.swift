import Foundation
import SocialLoginSDK

enum DemoEnvironmentConfig {
    /// Backend Base URL / Client ID come from Info.plist
    /// (`SocialLoginStagingBaseURL`, `SocialLoginProductionBaseURL`, `SocialLoginClientID`).
    /// Google / Facebook credentials also come from Info.plist.
    static func configuration(for environment: SocialLoginEnvironment) -> SocialLoginConfiguration {
        SocialLoginConfiguration(environment: environment)
    }
}
