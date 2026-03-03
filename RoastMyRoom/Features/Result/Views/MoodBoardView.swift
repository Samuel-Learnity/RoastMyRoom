import SwiftUI

struct MoodBoardView: View {
    let moodBoard: MoodBoard
    let isBlurred: Bool
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            paletteSection
            suggestionsSection
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

    // MARK: - Palette

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "moodboard_palette_label"), systemImage: "paintpalette.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 12) {
                ForEach(moodBoard.colorPalette, id: \.self) { hex in
                    let color = Color(hex: hex) ?? .gray
                    VStack(spacing: 4) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: color.opacity(0.4), radius: 4)

                        Text(hex)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .redacted(reason: isBlurred ? .placeholder : [])
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(String(localized: "moodboard_suggestions_label"), systemImage: "wand.and.stars")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(Array(moodBoard.suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.aiPurple)
                            .frame(width: 24, height: 24)
                            .background(Color.aiPurple.opacity(0.15), in: Circle())

                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                    .redacted(reason: isBlurred && index > 0 ? .placeholder : [])
                }
            }
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
        MoodBoardView(
            moodBoard: MoodBoard(
                colorPalette: ["#E8D5B7", "#2C3E50", "#D4A574", "#8B9DC3", "#F5E6CC"],
                suggestions: [
                    "Un tapis berb\u{00e8}re beige 160\u{00d7}230",
                    "Remplacer l'ampoule par une 2700K",
                    "Ajouter 2-3 coussins bleu marine"
                ]
            ),
            isBlurred: false
        )
        .padding()
    }
}
