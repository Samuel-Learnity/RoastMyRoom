import SwiftUI

struct PersonalityCardView: View {
    let personality: PersonalityAnalysis
    let isBlurred: Bool
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            traitsRow
            celebrityRow
            datingRow
                .redacted(reason: isBlurred ? .placeholder : [])
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground()
        .overlay { blurOverlay }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Traits

    private var traitsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "personality_traits_label"), systemImage: "brain.head.profile.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))

            FlowLayout(spacing: 8) {
                ForEach(Array(personality.traits.enumerated()), id: \.offset) { index, trait in
                    Text(trait)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .fixedSize()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.aiPurple.opacity(0.2), in: Capsule())
                        .overlay(Capsule().stroke(Color.aiPurple.opacity(0.3), lineWidth: 1))
                        .redacted(reason: isBlurred && index > 0 ? .placeholder : [])
                }
            }
        }
    }

    // MARK: - Celebrity Match

    private var celebrityName: String {
        let parts = personality.celebrityMatch.components(separatedBy: " \u{2014} ")
        return parts.first ?? personality.celebrityMatch
    }

    private var celebrityQuote: String? {
        let parts = personality.celebrityMatch.components(separatedBy: " \u{2014} ")
        return parts.count > 1 ? parts.dropFirst().joined(separator: " \u{2014} ") : nil
    }

    private var celebrityRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(String(localized: "personality_celebrity_label"), systemImage: "star.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))

            VStack(alignment: .leading, spacing: 4) {
                Text(celebrityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .neonGlow(colors: [.aiPurple, .aiPink, .aiLightBlue], radius: 8, opacity: 0.4)

                if let quote = celebrityQuote {
                    Text(quote)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.white.opacity(0.7))
                        .redacted(reason: isBlurred ? .placeholder : [])
                }
            }
        }
    }

    // MARK: - Dating Line

    private var datingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(String(localized: "personality_dating_label"), systemImage: "heart.text.clipboard")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))

            Text(personality.datingLine)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Blur Overlay

    @ViewBuilder
    private var blurOverlay: some View {
        if isBlurred {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(8)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        PersonalityCardView(
            personality: PersonalityAnalysis(
                traits: ["Chronic overthinker", "IKEA loyalist", "Hopeless romantic"],
                celebrityMatch: "Nick Miller \u{2014} ce canap\u{00e9} a v\u{00e9}cu des choses",
                datingLine: "Ton date penserait que t'as un bon cr\u{00e9}dit immobilier."
            ),
            isBlurred: false
        )
        .padding()
    }
}
