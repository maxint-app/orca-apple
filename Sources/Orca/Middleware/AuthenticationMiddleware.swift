import OpenAPIRuntime
import HTTPTypes
import Foundation

struct AuthenticationMiddleware: ClientMiddleware {
    let apiKey: String
    let enableNetworkLogging: Bool

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields.append(HTTPField(name: .init("api-key")!, value: apiKey))

        if enableNetworkLogging {
            let path = request.path ?? ""
            let url = baseURL.appendingPathComponent(path)
            print("[Orca] -> \(operationID) \(request.method.rawValue) \(url.absoluteString)")
        }

        let (response, responseBody) = try await next(request, body, baseURL)

        guard enableNetworkLogging else {
            return (response, responseBody)
        }

        let contentType = response.headerFields[.contentType] ?? "<none>"
        var logMessage = "[Orca] <- \(operationID) status=\(response.status.code) content-type=\(contentType)"

        guard let responseBody else {
            print(logMessage)
            return (response, nil)
        }

        do {
            let maxBytes = 8 * 1024
            let raw = try await String(collecting: responseBody, upTo: maxBytes)
            let bodyPreview: String
            if raw.isEmpty {
                bodyPreview = "<empty>"
            } else {
                bodyPreview = raw.replacingOccurrences(of: "\n", with: "\\n")
            }
            logMessage += " body=\(bodyPreview)"
            print(logMessage)
            return (response, HTTPBody(raw))
        } catch {
            logMessage += " body=<unavailable: \(error.localizedDescription)>"
            print(logMessage)
            return (response, responseBody)
        }
    }
}
