import Foundation

public enum FacebookPermission: Sendable, CaseIterable {
    case publicProfile
    case email
}

public struct FacebookSignInConfiguration: Sendable {
    public let permissions: [FacebookPermission]

    public init(
        permissions: [FacebookPermission] = [.publicProfile, .email]
    ) {
        self.permissions = permissions
    }
}
