import Foundation

struct EunoraSession: Codable {
    struct User: Codable { let id: String }
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval?
    let user: User

    var needsRefresh: Bool {
        expiresAt.map { $0 <= Date.now.timeIntervalSince1970 + 30 } ?? true
    }
}

struct EunoraAPI {
    enum Failure: LocalizedError {
        case response(status: Int, message: String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case let .response(_, message): message
            case .invalidResponse: "Eunora couldn’t read the server’s reply."
            }
        }
    }

    struct AuthReply: Decodable {
        let session: EunoraSession?
        let needsConfirm: Bool?
    }

    private struct ErrorReply: Decodable { let error: String }

    let baseURL: URL
    var transport: URLSession = URLSession(configuration: .ephemeral)

    static var configured: Self? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "EunoraAPIBaseURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        return Self(baseURL: url)
    }

    func authenticate(email: String, password: String, sailorName: String?) async throws -> AuthReply {
        var body = ["email": email, "password": password]
        body["sailorName"] = sailorName
        let data = try await post(sailorName == nil ? "auth/login" : "auth/signup", body: body)
        return try JSONDecoder().decode(AuthReply.self, from: data)
    }

    func refresh(_ session: EunoraSession) async throws -> EunoraSession {
        let data = try await post("auth/refresh", body: ["refreshToken": session.refreshToken])
        let reply = try JSONDecoder().decode(AuthReply.self, from: data)
        guard let refreshed = reply.session, refreshed.user.id == session.user.id else {
            throw Failure.invalidResponse
        }
        return refreshed
    }

    func logout(_ session: EunoraSession) async throws {
        _ = try await post("auth/logout", token: session.accessToken)
    }

    private func post(_ path: String, body: [String: String]? = nil, token: String? = nil) async throws -> Data {
        let url = path.split(separator: "/").reduce(baseURL) { $0.appendingPathComponent(String($1)) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.httpMethod = "POST"
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        let (data, response) = try await transport.data(for: request, delegate: RejectRedirects())
        guard let http = response as? HTTPURLResponse else { throw Failure.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorReply.self, from: data))?.error
            throw Failure.response(status: http.statusCode, message: message ?? "Eunora couldn’t reach your account.")
        }
        return data
    }
}


private final class RejectRedirects: NSObject, URLSessionTaskDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
