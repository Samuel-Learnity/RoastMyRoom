import SwiftUI

struct ScoreCounterView: View {
    let score: Float
    let verdict: String
    var animated: Bool = true

    @State private var arcProgress: CGFloat = 0
    @State private var hasAnimated = false
    @State private var showVerdict = false

    private let ringSize: CGFloat = 180

    private var verdictText: String {
        verdict.isEmpty ? String(format: "%.1f", score) : verdict
    }

    private var verdictFontSize: CGFloat {
        let length = verdictText.count
        if length <= 3 { return 44 }
        if length <= 6 { return 34 }
        if length <= 10 { return 26 }
        return 20
    }

    /// Score-adaptive neon palette for the ambient glow
    private var glowColors: [Color] {
        switch score {
        case 0..<4: [Color.aiCoral, Color.aiPeach, Color.aiPink]
        case 4..<6: [Color.aiPeach, Color.aiCoral, Color.aiLavender]
        case 6..<8: [Color.aiLightBlue, Color.aiPurple, Color.aiLavender]
        default:    [Color.aiPurple, Color.aiPink, Color.aiLightBlue]
        }
    }

    var body: some View {
        ZStack {
            // Static neon glow backdrop
            Circle()
                .fill(
                    LinearGradient(
                        colors: glowColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: ringSize + 20, height: ringSize + 20)
                .blur(radius: 28)
                .opacity(0.5)

            // Glass disc
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: ringSize, height: ringSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            // Progress arc — gradient stroke
            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(
                    AngularGradient(
                        colors: glowColors + [glowColors[0]],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColors[0].opacity(0.5), radius: 10)

            // Verdict
            VStack(spacing: 4) {
                Text(verdictText)
                    .font(.system(size: verdictFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: ringSize - 40)
                    .opacity(showVerdict ? 1 : 0)
                    .scaleEffect(showVerdict ? 1 : 0.8)

                Text("/10")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .opacity(showVerdict ? 1 : 0)
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            if animated {
                withAnimation(.easeOut(duration: 1.2)) {
                    arcProgress = CGFloat(score) / 10.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                        showVerdict = true
                    }
                }
            } else {
                arcProgress = CGFloat(score) / 10.0
                showVerdict = true
            }
        }
    }
}

#Preview("High score") {
    ZStack {
        GradientBackground()
        ScoreCounterView(score: 8.5, verdict: "Clean AF")
    }
}

#Preview("Low score") {
    ZStack {
        GradientBackground()
        ScoreCounterView(score: 3.2, verdict: "Bof bof 😬")
    }
}
