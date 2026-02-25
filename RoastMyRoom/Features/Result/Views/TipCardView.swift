import SwiftUI

struct TipCardView: View {
    let tip: Tip
    let index: Int
    let isBlurred: Bool
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
                    .foregroundStyle(.primary)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .blur(radius: isBlurred ? 6 : 0)
        .overlay {
            if isBlurred {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(duration: 0.5).delay(Double(index) * 0.15 + 1.5)) {
                appeared = true
            }
        }
    }

    private var impactBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.rsSuccess.opacity(0.12))

                Capsule()
                    .fill(Color.rsSuccess.opacity(0.5))
                    .frame(width: geometry.size.width * CGFloat(tip.impact / 2.0))
            }
        }
        .frame(width: 60, height: 4)
    }
}

#Preview {
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
