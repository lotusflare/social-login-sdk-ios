import Foundation

enum BackendRequestBuilder {
    static func makeRequest(
        url: URL,
        method: String,
        backend: BackendConfiguration,
        accessToken: String? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(backend.clientID, forHTTPHeaderField: "X-Client-Id")
        request.setValue(backend.resolvedDeviceID(), forHTTPHeaderField: "X-Device-Id")

        if let accessToken, !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        backend.additionalHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Always last: one fresh UUID per HTTP attempt (including retries).
        request.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "X-Request-Id")

        return request
    }
}
