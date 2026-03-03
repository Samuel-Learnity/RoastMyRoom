import SwiftUI

struct TipCardView: View {
    let tip: Tip
    let index: Int
    let isBlurred: Bool
    var animated: Bool = true
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            // Numbered circle
            ZStack {
                Circle()
                    .fill(Color.rsAccent.opacity(0.12))
                    .frame(width: 36, height: 36)

                Text("\(index + 1)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.rsAccent)
            }

            // Tip text + impact bar
            VStack(alignment: .leading, spacing: 6) {
                Text(tip.text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Impact indicator
                HStack(spacing: 8) {
                    impactBar

                    Text("+\(String(format: "%.1f", tip.impact))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.rsSuccess)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(cornerRadius: 20)
        .redacted(reason: isBlurred ? .placeholder : [])
        .overlay {
            if isBlurred {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            if animated {
                withAnimation(.spring(duration: 0.5).delay(Double(index) * 0.12 + 0.3)) {
                    appeared = true
                }
            } else {
                appeared = true
            }
        }
    }

    private static let impactBarWidth: CGFloat = 60

    private var impactBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.rsSuccess.opacity(0.12))

            Capsule()
                .fill(Color.rsSuccess.opacity(0.5))
                .frame(width: Self.impactBarWidth * CGFloat(tip.impact / 2.0))
        }
        .frame(width: Self.impactBarWidth, height: 4)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        VStack(spacing: 12) {
            TipCardView(
                tip: Tip(text: "Replace the harsh overhead light with a warm floor lamp", impact: 0.8),
                index: 0,
                isBlurred: false
            )
            TipCardView(
                tip: Tip(text: "Pick a two-color palette and ditch the clashing pillows", impact: 0.6),
                index: 1,
                isBlurred: true
            )
        }
        .padding()
    }
}
