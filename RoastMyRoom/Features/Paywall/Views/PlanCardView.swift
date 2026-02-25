import SwiftUI
import StoreKit

struct PlanCardView: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool

    var body: some View {
        VStack(spacing: 8) {
            if isBestValue {
                Text(String(localized: "paywall_best_value"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rsAccent, in: Capsule())
            }

            VStack(spacing: 4) {
                Text(product.displayName)
                    .font(.headline)

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)

                if let subscription = product.subscription {
                    Text(periodLabel(subscription.subscriptionPeriod))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let intro = subscription.introductoryOffer,
                       intro.paymentMode == .freeTrial {
                        Text(trialLabel(intro.period))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rsAccent)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.rsAccent.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.rsAccent : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3), value: isSelected)
        }
    }

    private func periodLabel(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .week: return String(localized: "paywall_per_week")
        case .month: return String(localized: "paywall_per_month")
        case .year: return String(localized: "paywall_per_year")
        default: return ""
        }
    }

    private func trialLabel(_ period: Product.SubscriptionPeriod) -> String {
        let days = period.value * (period.unit == .week ? 7 : period.unit == .day ? 1 : 30)
        return String(localized: "paywall_trial_days \(days)")
    }
}
