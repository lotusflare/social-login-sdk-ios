import Foundation

final class SocialLoginBackendClient: SocialLoginBackendServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Social

    func fetchSocialNonce(
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<String, SocialLoginError>) -> Void
    ) {
        getJSON(
            path: BackendAPIPath.socialNonce,
            configuration: configuration,
            decode: SocialNonceResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let nonce = response.data?.nonce, !nonce.isEmpty else {
                    completion(.failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid backend response.")))
                    return
                }
                completion(.success(nonce))
            }
        }
    }

    func loginWithProvider(
        payload: ProviderAuthPayload,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        guard let idTokenValue = payload.idToken, !idTokenValue.isEmpty else {
            completion(.failure(.providerSignInFailed(payload.provider, message: "Missing provider token.")))
            return
        }
        guard let nonce = payload.nonce, !nonce.isEmpty else {
            completion(
                .failure(
                    .backendRequestFailed(statusCode: nil, code: nil, message: "Missing social nonce for backend login.")
                )
            )
            return
        }

        let body = SocialLoginRequest(
            loginType: payload.provider.rawValue,
            idToken: idTokenValue,
            nonce: nonce,
            userName: payload.provider == .apple ? payload.userName : nil
        )

        postJSON(
            path: BackendAPIPath.socialSignIn,
            body: body,
            configuration: configuration,
            accessToken: nil,
            decode: BackendSessionResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let data = response.data,
                      let session = BackendSessionMapper.makeSession(
                          from: data,
                          environment: configuration.environment
                      ) else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid backend response."))
                    )
                    return
                }
                completion(.success(session))
            }
        }
    }

    func refreshToken(
        _ refreshToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginTokenRefresh, SocialLoginError>) -> Void
    ) {
        guard !refreshToken.isEmpty else {
            completion(.failure(.refreshTokenInvalid(message: "Missing refresh token.")))
            return
        }

        postJSON(
            path: BackendAPIPath.refreshToken,
            body: BackendRefreshRequest(refreshToken: refreshToken),
            configuration: configuration,
            accessToken: nil,
            decode: BackendRefreshResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let data = response.data,
                      let tokens = BackendSessionMapper.makeTokenRefresh(from: data) else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid refresh response."))
                    )
                    return
                }
                completion(.success(tokens))
            }
        }
    }

    func logout(
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        guard !accessToken.isEmpty else {
            completion(.success(()))
            return
        }

        postJSON(
            path: BackendAPIPath.signOut,
            body: EmptyJSONObject(),
            configuration: configuration,
            accessToken: accessToken,
            decode: BackendLogoutResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard response.data?.success == true else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid sign-out response."))
                    )
                    return
                }
                completion(.success(()))
            }
        }
    }

    // MARK: - Email auth

    func requestEmailSignUpCode(
        email: String,
        language: String?,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        postJSON(
            path: BackendAPIPath.emailSignUpGetCode,
            body: EmailGetCodeRequest(email: email, language: language),
            configuration: configuration,
            accessToken: nil,
            decode: EmailSignUpGetCodeResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let data = response.data
                completion(
                    .success(
                        EmailCodeSendResult(
                            email: data?.email,
                            codeSent: data?.codeSent,
                            needEmailVerify: data?.needEmailVerify,
                            resendAfterSec: data?.resendAfterSec,
                            lockRemainingSec: data?.lockRemainingSec
                        )
                    )
                )
            }
        }
    }

    func completeEmailSignUp(
        email: String,
        code: String,
        password: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailSignUpResult, SocialLoginError>) -> Void
    ) {
        if let policyError = PasswordPolicy.validate(password) {
            completion(.failure(policyError))
            return
        }

        postJSON(
            path: BackendAPIPath.emailSignUp,
            body: EmailSignUpRequest(email: email, code: code, password: password),
            configuration: configuration,
            accessToken: nil,
            decode: EmailSignUpResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let data = response.data,
                      let userID = data.userId,
                      !userID.isEmpty else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid sign-up response."))
                    )
                    return
                }
                completion(
                    .success(
                        EmailSignUpResult(
                            userID: userID,
                            email: data.email ?? email,
                            registerCompleted: data.registerCompleted ?? true
                        )
                    )
                )
            }
        }
    }

    func signInWithEmail(
        email: String,
        password: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<SocialLoginSession, SocialLoginError>) -> Void
    ) {
        postJSON(
            path: BackendAPIPath.emailSignIn,
            body: EmailSignInRequest(email: email, password: password),
            configuration: configuration,
            accessToken: nil,
            decode: BackendSessionResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard let data = response.data,
                      let session = BackendSessionMapper.makeSession(
                          from: data,
                          environment: configuration.environment
                      ) else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid sign-in response."))
                    )
                    return
                }
                completion(.success(session))
            }
        }
    }

    func isEmailRegistered(
        email: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailRegistrationStatus, SocialLoginError>) -> Void
    ) {
        postJSON(
            path: BackendAPIPath.emailIsRegistered,
            body: EmailIsRegisteredRequest(email: email),
            configuration: configuration,
            accessToken: nil,
            decode: EmailIsRegisteredResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let data = response.data
                let loginTypes = (data?.existsLoginTypes ?? []).compactMap(SocialLoginLoginType.init(rawValue:))
                completion(
                    .success(
                        EmailRegistrationStatus(
                            email: data?.email ?? email,
                            registered: data?.registered ?? false,
                            existsLoginTypes: loginTypes
                        )
                    )
                )
            }
        }
    }

    func requestPasswordResetCode(
        email: String,
        language: String?,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        postJSON(
            path: BackendAPIPath.passwordResetGetCode,
            body: EmailGetCodeRequest(email: email, language: language),
            configuration: configuration,
            accessToken: nil,
            decode: PasswordOperationResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let data = response.data
                completion(
                    .success(
                        EmailCodeSendResult(
                            success: data?.success,
                            resendAfterSec: data?.resendAfterSec,
                            lockRemainingSec: data?.lockRemainingSec
                        )
                    )
                )
            }
        }
    }

    func resetPassword(
        email: String,
        code: String,
        newPassword: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        if let policyError = PasswordPolicy.validate(newPassword) {
            completion(.failure(policyError))
            return
        }

        postJSON(
            path: BackendAPIPath.passwordReset,
            body: PasswordResetRequest(email: email, code: code, newPassword: newPassword),
            configuration: configuration,
            accessToken: nil,
            decode: PasswordOperationResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard response.data?.success == true else {
                    completion(
                        .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid reset response."))
                    )
                    return
                }
                completion(.success(()))
            }
        }
    }

    func requestPasswordChangeCode(
        language: String?,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<EmailCodeSendResult, SocialLoginError>) -> Void
    ) {
        guard !accessToken.isEmpty else {
            completion(.failure(.notConfigured))
            return
        }

        postJSON(
            path: BackendAPIPath.passwordChangeGetCode,
            body: PasswordChangeGetCodeRequest(language: language),
            configuration: configuration,
            accessToken: accessToken,
            decode: PasswordOperationResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let data = response.data
                completion(
                    .success(
                        EmailCodeSendResult(
                            success: data?.success,
                            resendAfterSec: data?.resendAfterSec,
                            lockRemainingSec: data?.lockRemainingSec
                        )
                    )
                )
            }
        }
    }

    func changePasswordWithCurrent(
        currentPassword: String,
        newPassword: String,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        changePassword(
            body: PasswordChangeWithCurrentRequest(currentPassword: currentPassword, newPassword: newPassword),
            newPassword: newPassword,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    func changePasswordWithCode(
        code: String,
        newPassword: String,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        changePassword(
            body: PasswordChangeWithCodeRequest(code: code, newPassword: newPassword),
            newPassword: newPassword,
            accessToken: accessToken,
            configuration: configuration,
            completion: completion
        )
    }

    // MARK: - Shared request helpers

    private struct EmptyJSONObject: Encodable {}

    private func changePassword<Body: Encodable>(
        body: Body,
        newPassword: String,
        accessToken: String,
        configuration: SocialLoginConfiguration,
        completion: @escaping (Result<Void, SocialLoginError>) -> Void
    ) {
        if let policyError = PasswordPolicy.validate(newPassword) {
            completion(.failure(policyError))
            return
        }

        guard !accessToken.isEmpty else {
            completion(.failure(.notConfigured))
            return
        }

        postJSON(
            path: BackendAPIPath.passwordChange,
            body: body,
            configuration: configuration,
            accessToken: accessToken,
            decode: PasswordOperationResponse.self
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard response.data?.success == true else {
                    completion(
                        .failure(
                            .backendRequestFailed(
                                statusCode: nil,
                                code: nil,
                                message: "Invalid change-password response."
                            )
                        )
                    )
                    return
                }
                completion(.success(()))
            }
        }
    }

    private func requireBackend<T>(
        _ configuration: SocialLoginConfiguration,
        completion: @escaping (Result<T, SocialLoginError>) -> Void
    ) -> BackendConfiguration? {
        guard let backend = configuration.backend else {
            completion(
                .failure(
                    .missingBackendConfiguration(
                        message: "Backend is not configured. Set Info.plist keys or pass BackendConfiguration."
                    )
                )
            )
            return nil
        }
        return backend
    }

    private func getJSON<Response: Decodable>(
        path: String,
        configuration: SocialLoginConfiguration,
        decode: Response.Type,
        completion: @escaping (Result<Response, SocialLoginError>) -> Void
    ) where Response: BackendCodedResponse {
        guard let backend = requireBackend(configuration, completion: completion) else { return }

        guard let url = backend.makeURL(path: path) else {
            completion(
                .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid URL for \(path)."))
            )
            return
        }

        let request = BackendRequestBuilder.makeRequest(url: url, method: "GET", backend: backend)
        send(request: request, decode: decode, completion: completion)
    }

    private func postJSON<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        configuration: SocialLoginConfiguration,
        accessToken: String?,
        decode: Response.Type,
        completion: @escaping (Result<Response, SocialLoginError>) -> Void
    ) where Response: BackendCodedResponse {
        guard let backend = requireBackend(configuration, completion: completion) else { return }

        guard let url = backend.makeURL(path: path) else {
            completion(
                .failure(.backendRequestFailed(statusCode: nil, code: nil, message: "Invalid URL for \(path)."))
            )
            return
        }

        var request = BackendRequestBuilder.makeRequest(
            url: url,
            method: "POST",
            backend: backend,
            accessToken: accessToken
        )
        do {
            request.httpBody = try BackendJSONCoder.encoder.encode(body)
        } catch {
            completion(
                .failure(.backendRequestFailed(statusCode: nil, code: nil, message: error.localizedDescription))
            )
            return
        }

        send(request: request, decode: decode, completion: completion)
    }

    private func send<Response: Decodable>(
        request: URLRequest,
        decode: Response.Type,
        completion: @escaping (Result<Response, SocialLoginError>) -> Void
    ) where Response: BackendCodedResponse {
        perform(request: request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let httpPayload):
                completion(
                    self.decodeEnvelope(
                        decode,
                        from: httpPayload.data,
                        statusCode: httpPayload.statusCode
                    )
                )
            }
        }
    }

    private struct HTTPPayload {
        let data: Data
        let statusCode: Int?
    }

    private func perform(
        request: URLRequest,
        completion: @escaping (Result<HTTPPayload, SocialLoginError>) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(
                    .failure(.backendRequestFailed(statusCode: nil, code: nil, message: error.localizedDescription))
                )
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode
            guard let data else {
                completion(
                    .failure(.backendRequestFailed(statusCode: statusCode, code: nil, message: "Empty response body."))
                )
                return
            }

            // Appauth business errors use HTTP 400 with body.code != 0.
            // Deliver body for envelope decoding; treat 5xx as immediate parse/failure path.
            if let statusCode, statusCode >= 500 {
                completion(.failure(BackendErrorParser.parse(data: data, statusCode: statusCode)))
                return
            }

            completion(.success(HTTPPayload(data: data, statusCode: statusCode)))
        }.resume()
    }

    private func decodeEnvelope<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        statusCode: Int?
    ) -> Result<T, SocialLoginError> where T: BackendCodedResponse {
        do {
            let decoded = try BackendJSONCoder.decoder.decode(type, from: data)
            guard let code = decoded.code, code == 0 else {
                return .failure(BackendErrorParser.parse(data: data, statusCode: statusCode))
            }
            return .success(decoded)
        } catch {
            if let statusCode, !(200...299).contains(statusCode) {
                return .failure(BackendErrorParser.parse(data: data, statusCode: statusCode))
            }
            return .failure(
                .backendRequestFailed(statusCode: statusCode, code: nil, message: "Invalid backend response.")
            )
        }
    }
}
