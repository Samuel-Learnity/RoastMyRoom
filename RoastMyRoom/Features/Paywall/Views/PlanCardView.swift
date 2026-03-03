import SwiftUI
import StoreKit

struct PlanCardView: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    var isActive: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Text(product.displayName)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: 20, alignment: .center)

            Spacer(minLength: 8)

            Text(product.displayPrice)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(minHeight: 28, alignment: .center)

            Spacer(minLength: 8)

            Group {
                if let subscription = product.subscription,
                   let intro = subscription.introductoryOffer,
                   intro.paymentMode == .freeTrial {
                    Text(trialLabel(intro.period))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rsAccent)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                } else {
                    Color.clear
                }
            }
            .frame(height: 32, alignment: .center)
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
        .overlay(alignment: .top) {
            if isActive {
                Text(String(localized: "paywall_active"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.aiLightBlue, in: Capsule())
                    .offset(y: -12)
            } else if isBestValue {
                Text(String(localized: "paywall_best_value"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rsAccent, in: Capsule())
                    .offset(y: -12)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
    }


    private func trialLabel(_ period: Product.SubscriptionPeriod) -> String {
        let days = period.value * (period.unit == .week ? 7 : period.unit == .day ? 1 : 30)
        return String(localized: "paywall_trial_days \(days)")
    }
}
