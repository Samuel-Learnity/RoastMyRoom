import SwiftUI

struct RoastBannerView: View {
    let roast: String
    @State private var visibleCharacters = 0
    @State private var appeared = false

    private var displayedText: String {
        String(roast.prefix(visibleCharacters))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.rsWarning)
                    .symbolEffect(.bounce, value: appeared)

                Text(String(localized: "roast_title"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rsWarning)
            }

            // Typewriter roast text
            Text(displayedText)
                .font(.body)
                .italic()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.rsWarning.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            appeared = true
            startTypewriter()
        }
    }

    private func startTypewriter() {
        let totalChars = roast.count
        guard totalChars > 0 else { return }

        // ~15ms per character for a fast typewriter
        let interval: Double = 0.015
        // Short delay before starting to let the view settle
        let startDelay: Double = 0.5

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(startDelay * 1000)))
            for i in 1...totalChars {
                visibleCharacters = i
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            }
        }
    }
}

#Preview {
    RoastBannerView(
        roast: "That one decorative pillow is doing community service for the whole couch."
    )
    .padding()
}
