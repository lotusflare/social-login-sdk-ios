import Combine
import Foundation
import SocialLoginSDK
import SwiftUI
import UIKit

@MainActor
final class DemoLoginViewModel: ObservableObject {
    @Published var environment: SocialLoginEnvironment = .staging
    @Published var session: SocialLoginSession?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isRestoringSession = false

    private var sessionObserver: NSObjectProtocol?

    var isLoggedIn: Bool {
        session != nil
    }

    init() {
        setup()
        sessionObserver = NotificationCenter.default.addObserver(
            forName: .demoSessionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.session = DemoSessionStore.load()
            }
        }
    }

    deinit {
        if let sessionObserver {
            NotificationCenter.default.removeObserver(sessionObserver)
        }
    }

    func setup() {
        let stored = DemoSessionStore.load()
        if let stored, stored.environment != environment {
            SocialLoginSDK.signOut(accessToken: stored.accessToken)
            DemoSessionStore.clear()
            session = nil
        }

        isRestoringSession = true
        errorMessage = nil

        if let error = SocialLoginSDK.setup(
            configuration: DemoEnvironmentConfig.configuration(for: environment)
        ) {
            session = nil
            errorMessage = error.localizedDescription
            isRestoringSession = false
            return
        }

        session = DemoSessionStore.load()
        errorMessage = nil
        isRestoringSession = false
    }

    func signIn(provider: SocialLoginProvider) {
        guard SocialLoginSDK.isProviderConfigured(provider) else {
            errorMessage = SocialLoginError.missingProviderConfiguration(provider).localizedDescription
            return
        }

        guard let presenter = RootViewControllerAccessor.topViewController() else {
            errorMessage = SocialLoginError.missingPresenter.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        SocialLoginSDK.signIn(provider: provider, from: presenter) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .success(let session):
                    DemoSessionStore.save(session)
                    self.session = session
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func refreshSession() {
        guard let refreshToken = session?.refreshToken, !refreshToken.isEmpty else {
            errorMessage = "No local refresh token."
            return
        }

        isLoading = true
        errorMessage = nil
        SocialLoginSDK.refreshToken(refreshToken) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let tokens):
                    if let current = self.session {
                        let updated = current.applying(tokens)
                        DemoSessionStore.save(updated)
                        self.session = updated
                    }
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        SocialLoginSDK.signOut(accessToken: session?.accessToken)
        DemoSessionStore.clear()
        session = nil
        errorMessage = nil
    }
}
