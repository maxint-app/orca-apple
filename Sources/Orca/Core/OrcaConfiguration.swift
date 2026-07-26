import Foundation

public struct OrcaConfiguration: Sendable {
    public let publicKey: String
    public let environment: OrcaEnvironment
    public let baseURL: String
    public let enableNetworkLogging: Bool
    public var customerEmail: String?

    public init(
        publicKey: String,
        environment: OrcaEnvironment,
        baseURL: String = "https://api.orca.maxint.com",
        enableNetworkLogging: Bool = false,
        customerEmail: String? = nil
    ) {
        self.publicKey = publicKey
        self.environment = environment
        self.baseURL = baseURL
        self.enableNetworkLogging = enableNetworkLogging
        self.customerEmail = customerEmail
    }
}

public enum OrcaEnvironment: String, Codable, Sendable {
    case sandbox
    case production = "prod"
}
