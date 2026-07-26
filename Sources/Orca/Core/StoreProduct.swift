import Foundation
import StoreKit

public enum StoreProduct: Identifiable, Sendable {
    case subscription(SubscriptionData)
    case consumable(ConsumableData)
    case nonConsumable(NonConsumableData)

    public var id: String {
        switch self {
        case .subscription(let data): return data.id
        case .consumable(let data): return data.id
        case .nonConsumable(let data): return data.id
        }
    }

    public var name: String {
        switch self {
        case .subscription(let data): return data.name
        case .consumable(let data): return data.name
        case .nonConsumable(let data): return data.name
        }
    }

    public var currencyCode: String {
        switch self {
        case .subscription(let data): return data.currencyCode
        case .consumable(let data): return data.currencyCode
        case .nonConsumable(let data): return data.currencyCode
        }
    }

    public var description: String {
        switch self {
        case .subscription(let data): return data.description
        case .consumable(let data): return data.description
        case .nonConsumable(let data): return data.description
        }
    }

    public var entitlement: Components.Schemas.TenantEntitlement {
        switch self {
        case .subscription(let data): return data.entitlement
        case .consumable(let data): return data.entitlement
        case .nonConsumable(let data): return data.entitlement
        }
    }

    public var price: Decimal {
        switch self {
        case .subscription(let data): return data.price
        case .consumable(let data): return data.price
        case .nonConsumable(let data): return data.price
        }
    }

    public var formattedPrice: String {
        switch self {
        case .subscription(let data): return data.formattedPrice
        case .consumable(let data): return data.formattedPrice
        case .nonConsumable(let data): return data.formattedPrice
        }
    }

    public var subscriptionPeriod: Product.SubscriptionPeriod? {
        if case .subscription(let data) = self {
            return data.subscriptionPeriod
        }
        return nil
    }

    public struct SubscriptionData: Sendable {
        public let id: String
        public let name: String
        public let currencyCode: String
        public let description: String
        public let entitlement: Components.Schemas.TenantEntitlement
        public let price: Decimal
        public let formattedPrice: String
        public let subscriptionPeriod: Product.SubscriptionPeriod?
    }

    public struct ConsumableData: Sendable {
        public let id: String
        public let name: String
        public let currencyCode: String
        public let description: String
        public let entitlement: Components.Schemas.TenantEntitlement
        public let price: Decimal
        public let formattedPrice: String
    }

    public struct NonConsumableData: Sendable {
        public let id: String
        public let name: String
        public let currencyCode: String
        public let description: String
        public let entitlement: Components.Schemas.TenantEntitlement
        public let price: Decimal
        public let formattedPrice: String
    }
}
