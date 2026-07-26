import SwiftUI
import StoreKit
import Orca

struct ProductCardView: View {
    let product: StoreProduct
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.formattedPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)
                    periodLabel
                }
            }

            Button(action: onPurchase) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isPurchasing)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }

    private var buttonTitle: String {
        switch product {
        case .subscription: return "Subscribe"
        case .nonConsumable: return "Purchase"
        case .consumable: return "Buy"
        }
    }

    @ViewBuilder
    private var periodLabel: some View {
        switch product {
        case .subscription(let data):
            if let period = data.subscriptionPeriod {
                Text(periodText(from: period))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .nonConsumable:
            Text("one-time")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .consumable:
            Text("consumable")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func periodText(from period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .week where period.value == 1:
            return "per week"
        case .month where period.value == 1:
            return "per month"
        case .year where period.value == 1:
            return "per year"
        case .day:
            return "per \(period.value) days"
        default:
            return "\(period.value) \(period.unit.debugDescription)"
        }
    }
}
