import SwiftUI

struct StyleBadgeView: View {
    let styleName: String
    @State private var appeared = false

    private var roomStyle: RoomStyle? {
        RoomStyle(rawValue: styleName)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: roomStyle?.icon ?? "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .symbolEffect(.pulse, options: .repeating, isActive: appeared)

            Text(styleName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.rsAccent.opacity(0.4), lineWidth: 1)
        )
        .neonGlow(colors: [Color.rsAccent, .purple, .pink], radius: 12, opacity: 0.5)
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        StyleBadgeView(styleName: "Student Chaos")
    }
}
