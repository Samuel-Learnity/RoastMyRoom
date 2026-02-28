import SwiftUI
import StoreKit

struct PlanCardView: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Badge — always reserves space, invisible when not best value
            Text(String(localized: "paywall_best_value"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.rsAccent, in: Capsule())
                .opacity(isBestValue ? 1 : 0)

            VStack(spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if let subscription = product.subscription {

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.rsAccent.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Color.rsAccent : Color.rsCardStroke, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3), value: isSelected)
            
            Spacer()
        }
    }


    private func trialLabel(_ period: Product.SubscriptionPeriod) -> String {
        let days = period.value * (period.unit == .week ? 7 : period.unit == .day ? 1 : 30)
        return String(localized: "paywall_trial_days \(days)")
    }
}
