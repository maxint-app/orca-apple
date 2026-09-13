# Orca Apple

Native Orca SDK for Apple platforms (iOS, macOS, tvOS, watchOS, visionOS).

Built with StoreKit 2 and Swift OpenAPI (openapi-generator) for the Orca backend API.

## Platforms

- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- visionOS 1+

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/maxint-app/orca-apple.git", branch: "main")
```

## Configuration

```swift
import Orca

Orca.configure(configuration: OrcaConfiguration(
  publicKey: "your_public_key",
  environment: .sandbox, // or .production
  customerEmail: "user@example.com" // optional
))
```

## Usage

```swift
import Orca

// identity
try await Orca.identify(customerEmail: "user@example.com")
Orca.logout()

// products & entitlements
let entitlements = try await Orca.listEntitlements()
let products = try await Orca.queryProducts()
let activeProducts = try await Orca.activeProduct()
let activeEntitlements = try await Orca.activeEntitlements()

// purchase
let product = products.first!
try await Orca.purchase(entitlement: product.entitlement)
```

## StoreProduct

`Orca.queryProducts()` returns `[StoreProduct]`, a sealed enum covering:

- `StoreProduct.subscription(SubscriptionData)`
- `StoreProduct.consumable(ConsumableData)`
- `StoreProduct.nonConsumable(NonConsumableData)`

Each variant carries `id`, `name`, `currencyCode`, `description`, `formattedPrice`, `price`, and its backing `TenantEntitlement`.

## Development

The OpenAPI client is generated from the Orca server OpenAPI spec:

```bash
# pull + filter the OpenAPI spec from a running Orca server
make filter-openapi

# regenerate Swift OpenAPI types
make generate
```

## License

MIT

© Copyright Maxint Inc. 2026
