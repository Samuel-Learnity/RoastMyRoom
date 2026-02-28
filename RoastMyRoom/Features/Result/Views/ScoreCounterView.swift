import SwiftUI

struct ScoreCounterView: View {
    let score: Float
    let verdict: String
    var animated: Bool = true
    @State private var arcProgress: CGFloat = 0
    @State private var hasAnimated = false
    @State private var showVerdict = false

    private var scoreColor: Color {
        Color.scoreColor(for: score)
    }

    private var verdictText: String {
        verdict.isEmpty ? String(format: "%.1f", score) : verdict
    }

    private var verdictFontSize: CGFloat {
        let length = verdictText.count
        if length <= 3 { return 42 }
        if length <= 6 { return 32 }
        if length <= 10 { return 24 }
        return 18
    }

    var body: some View {
        ZStack {
            // Glass disc backdrop
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 190, height: 190)

            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                .frame(width: 180, height: 180)

            // Outer glow ring
            Circle()
                .stroke(scoreColor.opacity(0.3), lineWidth: 8)
                .blur(radius: 12)
                .frame(width: 180, height: 180)

            // Progress arc
            Circle()
                .trim(from: 0, to: arcProgress)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(0.6), radius: 8)

            // Verdict text inside circle
            VStack(spacing: 2) {
                Text(verdictText)
                    .font(.system(size: verdictFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 150)
                    .opacity(showVerdict ? 1 : 0)
                    .scaleEffect(showVerdict ? 1 : 0.8)

                Text("/10")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.5))
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
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

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

#Preview {
    ZStack {
        GradientBackground()
        ScoreCounterView(score: 4.9, verdict: "Bof bof 😬")
    }
}
