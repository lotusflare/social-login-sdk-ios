import Foundation

public enum AppleSignInScope: Sendable, CaseIterable {
    case fullName
    case email
}

public struct AppleSignInConfiguration: Sendable {
    public let requestedScopes: [AppleSignInScope]

    public init(requestedScopes: [AppleSignInScope] = [.fullName, .email]) {
        self.requestedScopes = requestedScopes
    }
}
