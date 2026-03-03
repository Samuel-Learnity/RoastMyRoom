import SwiftUI

struct StyleBadgeView: View {
    let styleName: String

    private var roomStyle: RoomStyle? {
        RoomStyle(rawValue: styleName)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: roomStyle?.icon ?? "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .symbolEffect(.pulse)

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
        .shadow(color: Color.rsAccent.opacity(0.4), radius: 8)
    }
}

#Preview {
    ZStack {
        Color.black
        StyleBadgeView(styleName: "Student Chaos")
    }
}
