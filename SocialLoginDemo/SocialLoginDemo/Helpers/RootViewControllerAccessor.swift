import SwiftUI
import UIKit

struct RootViewControllerAccessor {
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let keyWindow = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        var topController = keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }
}
