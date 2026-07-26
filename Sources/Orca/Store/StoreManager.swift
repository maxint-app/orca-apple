import Foundation
import StoreKit

public enum StoreError: Error {
    case userCancelled
    case pending
    case unverifiedTransaction
    case productNotFound(String)
    case alreadyOwned(String)
    case unknown
}

actor StoreManager {

    private var transactionListenerTask: Task<Void, Never>?

    func fetchProducts(for entitlements: [Components.Schemas.TenantEntitlement]) async throws -> [Product] {
        let productIDs = entitlements.map { $0.products.appstore.product_id }
        let uniqueIDs = Array(Set(productIDs))
        guard !uniqueIDs.isEmpty else { return [] }
        return try await Product.products(for: uniqueIDs)
    }

    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verify(verification)
            await transaction.finish()
            return transaction

        case .userCancelled:
            throw StoreError.userCancelled

        case .pending:
            throw StoreError.pending

        @unknown default:
            throw StoreError.unknown
        }
    }

    func checkCurrentEntitlementProductIDs() async -> Set<String> {
        var productIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verify(result) {
                if transaction.revocationDate == nil {
                    productIDs.insert(transaction.productID)
                }
            }
        }
        return productIDs
    }

    func startObservingTransactionUpdates(onUpdate: @escaping @Sendable (Transaction) -> Void) {
        transactionListenerTask?.cancel()
        transactionListenerTask = Task.detached {
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                if let transaction = try? await self.verify(result) {
                    await self.handleTransactionUpdate(transaction)
                    onUpdate(transaction)
                }
            }
        }
    }

    func stopObserving() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
    }

    func mapToStoreProducts(
        _ platformProducts: [Product],
        entitlements: [Components.Schemas.TenantEntitlement]
    ) -> [StoreProduct] {
        let productByID = Dictionary(
            uniqueKeysWithValues: platformProducts.map { ($0.id, $0) }
        )
        let currencyCode = Locale.current.currencyCode ?? "USD"

        return entitlements.compactMap { entitlement -> StoreProduct? in
            let productID = entitlement.products.appstore.product_id
            guard let product = productByID[productID] else { return nil }

            switch entitlement.entitlement_type {
            case .subscription:
                return .subscription(
                    StoreProduct.SubscriptionData(
                        id: product.id,
                        name: product.displayName,
                        currencyCode: currencyCode,
                        description: product.description,
                        entitlement: entitlement,
                        price: product.price,
                        formattedPrice: product.displayPrice,
                        subscriptionPeriod: product.subscription?.subscriptionPeriod
                    )
                )

            case .consumable:
                return .consumable(
                    StoreProduct.ConsumableData(
                        id: product.id,
                        name: product.displayName,
                        currencyCode: currencyCode,
                        description: product.description,
                        entitlement: entitlement,
                        price: product.price,
                        formattedPrice: product.displayPrice
                    )
                )

            case .non_consumable:
                return .nonConsumable(
                    StoreProduct.NonConsumableData(
                        id: product.id,
                        name: product.displayName,
                        currencyCode: currencyCode,
                        description: product.description,
                        entitlement: entitlement,
                        price: product.price,
                        formattedPrice: product.displayPrice
                    )
                )
            }
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.unverifiedTransaction
        }
    }

    private func handleTransactionUpdate(_ transaction: Transaction) async {
        await transaction.finish()
    }
}
