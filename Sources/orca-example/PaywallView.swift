import SwiftUI
import StoreKit
import Orca

enum PaywallState {
    case loading
    case error(String)
    case empty
    case products([StoreProduct])
}

struct PaywallView: View {
    let customerEmail: String

    @State private var state: PaywallState = .loading
    @State private var purchasingProductId: String?

    var body: some View {
        ZStack {
            switch state {
            case .loading:
                ProgressView()
                    .scaleEffect(1.5)

            case .error(let message):
                VStack(spacing: 16) {
                    Text("Error")
                        .font(.title2)
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Close") {
                        state = .loading
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)

            case .empty:
                VStack(spacing: 16) {
                    Text("No Products Available")
                        .font(.title2)
                    Text("Check back later for subscription options")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Close") {
                        state = .loading
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)

            case .products(let products):
                ScrollView {
                    LazyVStack(spacing: 16) {
                        PaywallHeaderView()

                        ForEach(products, id: \.id) { product in
                            ProductCardView(
                                product: product,
                                isPurchasing: purchasingProductId == product.id,
                                onPurchase: {
                                    purchase(product)
                                }
                            )
                        }

                        Button("Maybe Later") {
                            state = .loading
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 16)
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #elseif os(macOS)
        .background(Color(.windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .task {
            await loadProducts()
        }
    }

    private func loadProducts() async {
        do {
            state = .loading
            try await Orca.identify(customerEmail: customerEmail)
            let products = try await Orca.queryProducts()
            if products.isEmpty {
                state = .empty
            } else {
                state = .products(products)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func purchase(_ product: StoreProduct) {
        purchasingProductId = product.id
        Task {
            do {
                try await Orca.purchase(entitlement: product.entitlement)
            } catch {
                state = .error(error.localizedDescription)
            }
            purchasingProductId = nil
        }
    }
}
