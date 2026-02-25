import SwiftUI

struct ScoreCounterView: View {
    let score: Float
    @State private var displayedScore: Float = 0
    @State private var arcProgress: CGFloat = 0
    @State private var hasAnimated = false

    private var scoreColor: Color {
        Color.scoreColor(for: score)
    }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
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

            // Score text
            VStack(spacing: 2) {
                Text(String(format: "%.1f", displayedScore))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("/10")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            withAnimation(.spring(duration: 1.2, bounce: 0.3)) {
                displayedScore = score
            }

            withAnimation(.easeOut(duration: 1.2)) {
                arcProgress = CGFloat(score) / 10.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScoreCounterView(score: 4.9)
    }
}
