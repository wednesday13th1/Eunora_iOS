import Foundation
import XCTest

final class APIContractTests: XCTestCase {
    @MainActor
    func testSignupDecodesConfirmationWithoutSession() async throws {
        let reply = try await client().authenticate(email: "sailor@example.invalid", password: "fixture-password", sailorName: "Sailor")
        XCTAssertEqual(reply.needsConfirm, true)
        XCTAssertNil(reply.session)
    }

    @MainActor
    func testRefreshMapsExpiredSessionAndRejectsAnotherUser() async throws {
        let session = EunoraSession(accessToken: "old", refreshToken: "expired", expiresAt: 0, user: .init(id: "sailor-a"))
        XCTAssertTrue(session.needsRefresh)
        do {
            _ = try await client().refresh(session)
            XCTFail("Expected an expired-session response")
        } catch EunoraAPI.Failure.response(status: 401, message: let message) {
            XCTAssertEqual(message, "Your login has expired.")
        }

        let mismatched = EunoraSession(accessToken: "old", refreshToken: "fixture", expiresAt: 0, user: .init(id: "sailor-a"))
        do {
            _ = try await client().refresh(mismatched)
            XCTFail("Expected a cross-account response to be rejected")
        } catch EunoraAPI.Failure.invalidResponse {}
    }

    @MainActor
    func testOfflineTransportErrorIsPreserved() async throws {
        do {
            _ = try await client().authenticate(email: "sailor@example.invalid", password: "fixture", sailorName: nil)
            XCTFail("Expected an offline transport error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }

    private func client() -> EunoraAPI {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        return EunoraAPI(baseURL: URL(string: "https://eunora.example.invalid")!,
                         transport: URLSession(configuration: configuration))
    }
}

private final class FixtureProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, request.httpMethod == "POST" else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let status: Int
        let body: String
        switch url.path {
        case "/auth/signup":
            status = 201
            body = #"{"session":null,"needsConfirm":true}"#
        case "/auth/refresh":
            let payload = request.httpBody ?? readBodyStream()
            let fields = payload.flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
            if fields?["refreshToken"] == "expired" {
                status = 401
                body = #"{"error":"Your login has expired."}"#
            } else {
                status = 200
                body = #"{"session":{"accessToken":"new","refreshToken":"new","expiresAt":null,"user":{"id":"sailor-b"}}}"#
            }
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private func readBodyStream() -> Data? {
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 256)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { return nil }
            if count == 0 { return data }
            data.append(contentsOf: buffer.prefix(count))
        }
    }
}
