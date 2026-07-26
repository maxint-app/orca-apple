import Testing
import Foundation
import OpenAPIRuntime
@testable import Orca

struct OrcaConfigurationTests {

    @Test func defaultBaseURL() {
        let config = OrcaConfiguration(
            publicKey: "test-key",
            environment: .sandbox
        )
        #expect(config.baseURL == "https://api.orca.maxint.com")
        #expect(config.customerEmail == nil)
    }

    @Test func customBaseURL() {
        let config = OrcaConfiguration(
            publicKey: "test-key",
            environment: .production,
            baseURL: "https://custom.api.com",
            customerEmail: "test@example.com"
        )
        #expect(config.baseURL == "https://custom.api.com")
        #expect(config.customerEmail == "test@example.com")
    }

    @Test func environmentRawValues() {
        #expect(OrcaEnvironment.sandbox.rawValue == "sandbox")
        #expect(OrcaEnvironment.production.rawValue == "prod")
    }

    @Test func configurationIsSendable() {
        let config = OrcaConfiguration(publicKey: "key", environment: .sandbox)
        let task = Task { config }
        _ = task
    }
}

struct StoreProductTests {

    @Test func subscriptionProductComputedProperties() {
        let product = StoreProduct.subscription(
            StoreProduct.SubscriptionData(
                id: "sub.monthly",
                name: "Premium Monthly",
                currencyCode: "USD",
                description: "Monthly premium",
                entitlement: makeTestEntitlement(id: "ent-1", type: .subscription),
                price: 9.99,
                formattedPrice: "$9.99",
                subscriptionPeriod: nil
            )
        )
        #expect(product.id == "sub.monthly")
        #expect(product.name == "Premium Monthly")
        #expect(product.currencyCode == "USD")
        #expect(product.price == 9.99)
        #expect(product.formattedPrice == "$9.99")
        #expect(product.subscriptionPeriod == nil)
    }

    @Test func consumableProductComputedProperties() {
        let product = StoreProduct.consumable(
            StoreProduct.ConsumableData(
                id: "consumable.coins",
                name: "100 Coins",
                currencyCode: "EUR",
                description: "Virtual currency",
                entitlement: makeTestEntitlement(id: "ent-2", type: .consumable),
                price: 1.99,
                formattedPrice: "1,99 \u{20ac}"
            )
        )
        #expect(product.id == "consumable.coins")
        #expect(product.name == "100 Coins")
        #expect(product.currencyCode == "EUR")
        #expect(product.subscriptionPeriod == nil)
    }
}

struct APIModelTests {

    @Test func tenantEntitlementDecoding() throws {
        let json = """
        {
            "description": "Premium subscription",
            "entitlement_type": "subscription",
            "id": "ent-1",
            "metadata": "",
            "name": "Premium",
            "period_ms": 2592000000,
            "products": {
                "appstore": {
                    "description": "App Store product",
                    "id": "prod-1",
                    "metadata": "",
                    "name": "Premium",
                    "product_id": "com.maxint.premium.monthly"
                },
                "gocardless": {
                    "description": null,
                    "id": "gc-1",
                    "metadata": "",
                    "name": "Premium GC",
                    "product_id": "gc-prod-1"
                },
                "playstore": {
                    "description": null,
                    "id": "ps-1",
                    "metadata": "",
                    "name": "Premium PS",
                    "product_id": "premium:monthly"
                },
                "stripe": {
                    "description": null,
                    "id": "st-1",
                    "metadata": "",
                    "name": "Premium Stripe",
                    "product_id": "str-prod-1"
                }
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let entitlement = try decoder.decode(Components.Schemas.TenantEntitlement.self, from: json)

        #expect(entitlement.id == "ent-1")
        #expect(entitlement.name == "Premium")
        #expect(entitlement.entitlement_type == .subscription)
        #expect(entitlement.products.appstore.product_id == "com.maxint.premium.monthly")
        #expect(entitlement.products.playstore.product_id == "premium:monthly")
    }

    @Test func storableEntitlementDecoding() throws {
        let json = """
        {
            "entitlement_id": "ent-1",
            "entitlement_type": "subscription",
            "expires_at": 1720000000,
            "id": "st-1",
            "product_id": "com.maxint.premium.monthly",
            "status": "active",
            "store": "appstore",
            "trial_expires_at": null,
            "purchase_state": null,
            "renewal_status": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let entitlement = try decoder.decode(Components.Schemas.StorableEntitlement.self, from: json)

        #expect(entitlement.id == "st-1")
        #expect(entitlement.entitlement_id == "ent-1")
        #expect(entitlement.store == "appstore")
        #expect(entitlement.status == "active")
        #expect(entitlement.trial_expires_at == nil)
    }

    @Test func tenantIdentifyUserInputBodyEncoding() throws {
        let body = Components.Schemas.TenantIdentifyUserInputBody(customer_email: "test@example.com")
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(json?["customer_email"] == "test@example.com")
    }
}

struct OrcaErrorTests {

    @Test func notConfiguredDescription() {
        #expect(OrcaError.notConfigured.errorDescription?.contains("not configured") == true)
    }

    @Test func customerNotIdentifiedDescription() {
        #expect(OrcaError.customerNotIdentified.errorDescription?.contains("not identified") == true)
    }

    @Test func productNotFoundDescription() {
        let error = OrcaError.productNotFound("prod-1")
        #expect(error.errorDescription?.contains("prod-1") == true)
    }

    @Test func alreadyOwnedDescription() {
        let error = OrcaError.alreadyOwned("Premium")
        #expect(error.errorDescription?.contains("Premium") == true)
    }
}

private func makeTestEntitlement(
    id: String,
    type: Components.Schemas.TenantEntitlement.entitlement_typePayload
) -> Components.Schemas.TenantEntitlement {
    let product = Components.Schemas.TenantEntitlementProduct(
        description: nil,
        id: "p-\(id)",
        metadata: .init(),
        name: "Product",
        product_id: "com.test.\(id)"
    )
    let products = Components.Schemas.TenantProducts(
        appstore: product,
        gocardless: product,
        playstore: product,
        stripe: product
    )
    return Components.Schemas.TenantEntitlement(
        description: nil,
        entitlement_type: type,
        id: id,
        metadata: .init(),
        name: "Test \(id)",
        period_ms: nil,
        products: products
    )
}
