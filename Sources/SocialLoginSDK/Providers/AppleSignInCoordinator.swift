import AuthenticationServices
import UIKit

final class AppleSignInCoordinator: NSObject {
    private var continuation: ((Result<ASAuthorizationAppleIDCredential, SocialLoginError>) -> Void)?
    private weak var anchorWindow: UIWindow?

    func start(
        scopes: [AppleSignInScope],
        hashedNonce: String?,
        presenting viewController: UIViewController,
        completion: @escaping (Result<ASAuthorizationAppleIDCredential, SocialLoginError>) -> Void
    ) {
        let begin: () -> Void = { [weak self] in
            guard let self else { return }
            guard let window = self.presentationAnchor(for: viewController) else {
                completion(.failure(.missingPresenter))
                return
            }

            self.anchorWindow = window
            self.continuation = completion

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = scopes.map(\.asAuthorizationScope)
            if let hashedNonce, !hashedNonce.isEmpty {
                request.nonce = hashedNonce
            }

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        if Thread.isMainThread {
            begin()
        } else {
            DispatchQueue.main.async(execute: begin)
        }
    }

    private func presentationAnchor(for viewController: UIViewController) -> UIWindow? {
        if let window = viewController.view.window {
            return window
        }

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        return scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private func finish(with result: Result<ASAuthorizationAppleIDCredential, SocialLoginError>) {
        continuation?(result)
        continuation = nil
        anchorWindow = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(.providerSignInFailed(.apple, message: "Unexpected credential type.")))
            return
        }

        finish(with: .success(credential))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue {
            finish(with: .failure(.cancelled))
            return
        }

        finish(with: .failure(.providerSignInFailed(.apple, message: error.localizedDescription)))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let anchorWindow {
            return anchorWindow
        }

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow
        }

        return scenes.flatMap(\.windows).first ?? UIWindow()
    }
}

private extension AppleSignInScope {
    var asAuthorizationScope: ASAuthorization.Scope {
        switch self {
        case .fullName:
            return .fullName
        case .email:
            return .email
        }
    }
}
