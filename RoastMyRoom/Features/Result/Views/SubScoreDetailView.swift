import SwiftUI

struct SubScoreDetailView: View {
    let subScores: SubScores
    let comments: SubScoreComments
    let isBlurred: Bool

    private var rows: [(label: String, icon: String, score: Float, comment: String)] {
        [
            (String(localized: "radar_color"), "paintpalette.fill", subScores.colorHarmony, comments.colorHarmony),
            (String(localized: "radar_proportions"), "arrow.up.left.and.arrow.down.right", subScores.proportions, comments.proportions),
            (String(localized: "radar_lighting"), "sun.max.fill", subScores.lighting, comments.lighting),
            (String(localized: "radar_cleanliness"), "sparkles", subScores.cleanliness, comments.cleanliness),
            (String(localized: "radar_personality"), "heart.fill", subScores.personality, comments.personality)
        ]
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                SubScoreRow(
                    label: row.label,
                    icon: row.icon,
                    score: row.score,
                    comment: row.comment,
                    index: index
                )
            }
        }
        .redacted(reason: isBlurred ? .placeholder : [])
        .overlay { premiumOverlay }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var premiumOverlay: some View {
        if isBlurred {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
    }
}

// MARK: - Row

private struct SubScoreRow: View {
    let label: String
    let icon: String
    let score: Float
    let comment: String
    let index: Int
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.scoreColor(for: score))
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Spacer()

                Text(String(format: "%.1f", score))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.scoreColor(for: score))
            }

            Text(comment)
                .font(.caption)
                .italic()
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(cornerRadius: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(duration: 0.4).delay(Double(index) * 0.08)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        ScrollView {
            SubScoreDetailView(
                subScores: SubScores(
                    colorHarmony: 5.5,
                    proportions: 5.0,
                    lighting: 6.0,
                    cleanliness: 6.5,
                    personality: 3.2
                ),
                comments: SubScoreComments(
                    colorHarmony: "Ces couleurs se battent en duel et personne gagne.",
                    proportions: "T'as mis les meubles au hasard ou c'\u{00e9}tait volontaire ?",
                    lighting: "L'\u{00e9}clairage dit 'salle d'attente chez le dentiste'.",
                    cleanliness: "Pas d\u{00e9}gueulasse, mais ta m\u{00e8}re serait pas fi\u{00e8}re.",
                    personality: "Y'a autant de personnalit\u{00e9} qu'un hall d'a\u{00e9}roport."
                ),
                isBlurred: false
            )
        }
    }
}
