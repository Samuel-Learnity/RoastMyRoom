import SwiftUI

struct RoastBannerView: View {
    let roast: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.rsWarning)

                Text(String(localized: "roast_title"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rsWarning)
            }

            Text(roast)
                .font(.body)
                .italic()
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aiGlow(
            colors: [Color.rsWarning, .red, .orange, Color(red: 1.0, green: 0.3, blue: 0.1)],
            cornerRadius: 20,
            glowRadius: 10,
            glowOpacity: 0.5,
            duration: 15
        )
    }
}

#Preview {
    ZStack {
        GradientBackground()
        RoastBannerView(
            roast: "That one decorative pillow is doing community service for the whole couch."
        )
        .padding()
    }
}
