import CryptoKit
import Foundation

enum NonceHasher {
    /// Returns lowercase hex SHA256 of the raw nonce for Apple Sign In `request.nonce`.
    static func sha256Hex(_ rawNonce: String) -> String {
        let digest = SHA256.hash(data: Data(rawNonce.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
