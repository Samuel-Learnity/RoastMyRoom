import SwiftUI
import StoreKit

struct PointsPackCardView: View {
    let product: Product
    let pack: PointsPack
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            if pack.isBestValue {
                Text(String(localized: "paywall_best_value"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rsAccent, in: Capsule())
            }

            VStack(spacing: 4) {
                Text("\(pack.points)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(String(localized: "paywall_points_label"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Text(product.displayPrice)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
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
        }
    }
}
