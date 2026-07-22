import SocialLoginSDK
import SwiftUI

@main
struct SocialLoginDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    _ = SocialLoginSDK.handleOpenURL(url)
                }
        }
    }
}
