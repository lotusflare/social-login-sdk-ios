import Foundation
import UIKit

protocol SocialLoginProviderType: AnyObject {
    func configure(with configuration: SocialLoginConfiguration)
    func signIn(
        from viewController: UIViewController,
        rawNonce: String,
        completion: @escaping (Result<ProviderAuthPayload, SocialLoginError>) -> Void
    )
    func signOut()
    func handleOpenURL(_ url: URL) -> Bool
}
