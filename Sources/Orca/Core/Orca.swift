import Foundation
import StoreKit
import OpenAPIRuntime
import OpenAPIURLSession

@MainActor
public enum Orca {

    private static var configuration: OrcaConfiguration?
    private static var client: Client?
    private static var customerId: String?

    private static let storeManager = StoreManager()

    private static var cachedEntitlements: [Components.Schemas.StorableEntitlement]?
    private static var cachedStoreProducts: [StoreProduct]?
    private static var cachedPlatformProducts: [Product]?
    private static var cachedTenantEntitlements: [Components.Schemas.TenantEntitlement]?

    // MARK: - Configuration

    public static func configure(configuration: OrcaConfiguration) {
        self.configuration = configuration

        let transport = URLSessionTransport()
        client = Client(
            serverURL: URL(string: configuration.baseURL)!,
            transport: transport,
            middlewares: [
                AuthenticationMiddleware(
                    apiKey: configuration.publicKey,
                    enableNetworkLogging: configuration.enableNetworkLogging
                )
            ]
        )
        customerId = nil

        Task {
            await storeManager.startObservingTransactionUpdates { transaction in
                Task { @MainActor in
                    cachedEntitlements = nil
                }
            }
        }
    }

    // MARK: - Identity

    public static func identify(customerEmail: String) async throws {
        try ensureConfigured()

        let input = Operations.postTenantIdentify.Input(
            body: .json(Components.Schemas.TenantIdentifyUserInputBody(customer_email: customerEmail))
        )

        let response = try await client!.postTenantIdentify(input)

        switch response {
        case .ok(let ok):
            guard case .json(let body) = ok.body else {
                throw OrcaError.invalidResponse
            }
            customerId = body.customer_id
            configuration?.customerEmail = customerEmail

        case .default(let statusCode, let failure):
            switch failure.body {
            case .application_problem_plus_json(let model):
                let message = model.detail ?? model.title ?? "Request failed"
                throw OrcaError.apiError(statusCode: statusCode, message: message)
            }
        }
    }

    public static func logout() {
        configuration?.customerEmail = nil
        customerId = nil
        cachedEntitlements = nil
        cachedStoreProducts = nil
        cachedPlatformProducts = nil
        cachedTenantEntitlements = nil
    }

    // MARK: - Products

    public static func queryProducts() async throws -> [StoreProduct] {
        try ensureConfigured()

        if let cached = cachedStoreProducts {
            return cached
        }

        let entitlements = try await listEntitlements()
        let platformProducts = try await fetchPlatformProducts(entitlements: entitlements)
        let storeProducts = await storeManager.mapToStoreProducts(platformProducts, entitlements: entitlements)

        cachedStoreProducts = storeProducts
        return storeProducts
    }

    public static func activeProduct() async throws -> [StoreProduct] {
        try ensureConfigured()

        let activeEntitlements = try await activeEntitlements()
        let allEntitlements = try await listEntitlements()
        let platformProducts = try await fetchPlatformProducts(entitlements: allEntitlements)
        let storeProducts = await storeManager.mapToStoreProducts(platformProducts, entitlements: allEntitlements)

        let activeIDs = Set(activeEntitlements.map(\.entitlement_id))
        return storeProducts.filter { activeIDs.contains($0.entitlement.id) }
    }

    // MARK: - Entitlements

    public static func activeEntitlements() async throws -> [Components.Schemas.StorableEntitlement] {
        try ensureConfigured()

        if let cached = cachedEntitlements {
            return cached
        }

        guard let email = configuration?.customerEmail else {
            throw OrcaError.customerNotIdentified
        }

        let env = configuration!.environment.rawValue

        let input = Operations.postTenantEntitlementsActive.Input(
            body: .json(Components.Schemas.TenantActiveEntitlementsInputBody(
                customer_email: email,
                environment: env
            ))
        )

        let response = try await client!.postTenantEntitlementsActive(input)

        guard case .ok(let ok) = response,
              case .json(let body) = ok.body
        else {
            throw OrcaError.invalidResponse
        }

        let entitlements = body.data ?? []
        cachedEntitlements = entitlements
        return entitlements
    }

    public static func listEntitlements() async throws -> [Components.Schemas.TenantEntitlement] {
        try ensureConfigured()

        if let cached = cachedTenantEntitlements {
            return cached
        }

        let env = configuration!.environment.rawValue

        let input = Operations.getTenantEntitlementsByEnvironment.Input(
            path: .init(environment: env)
        )

        let response = try await client!.getTenantEntitlementsByEnvironment(input)

        guard case .ok(let ok) = response,
              case .json(let body) = ok.body
        else {
            throw OrcaError.invalidResponse
        }

        let entitlements = body.data ?? []
        cachedTenantEntitlements = entitlements
        return entitlements
    }

    // MARK: - Purchase

    public static func purchase(entitlement: Components.Schemas.TenantEntitlement) async throws {
        try ensureConfigured()

        let productID = entitlement.products.appstore.product_id

        let allEntitlements = try await listEntitlements()
        let platformProducts = try await fetchPlatformProducts(entitlements: allEntitlements)

        guard let product = platformProducts.first(where: { $0.id == productID }) else {
            throw OrcaError.productNotFound(productID)
        }

        if entitlement.entitlement_type == .non_consumable {
            let active = try await activeEntitlements()
            if active.contains(where: { $0.entitlement_id == entitlement.id }) {
                throw OrcaError.alreadyOwned(entitlement.name)
            }
        }

        _ = try await storeManager.purchase(product)
        cachedEntitlements = nil
    }

    // MARK: - Private

    private static func ensureConfigured() throws {
        guard configuration != nil else {
            throw OrcaError.notConfigured
        }
    }

    private static func fetchPlatformProducts(
        entitlements: [Components.Schemas.TenantEntitlement]
    ) async throws -> [Product] {
        if let cached = cachedPlatformProducts {
            return cached
        }

        let products = try await storeManager.fetchProducts(for: entitlements)
        cachedPlatformProducts = products
        return products
    }
}

public enum OrcaError: Error, LocalizedError {
    case notConfigured
    case customerNotIdentified
    case productNotFound(String)
    case alreadyOwned(String)
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Orca is not configured. Call Orca.configure(configuration:) before using other methods."
        case .customerNotIdentified:
            return "Customer not identified. Call Orca.identify(customerEmail:) first."
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .alreadyOwned(let name):
            return "User already purchased non-consumable entitlement '\(name)'"
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let statusCode, let message):
            return "API error (status \(statusCode)): \(message)"
        }
    }
}
