import SwiftUI

struct RadarChartView: View {
    let subScores: SubScores
    var animated: Bool = true
    @State private var progress: CGFloat = 0
    @State private var labelsVisible = false

    private var values: [Float] {
        [
            subScores.colorHarmony,
            subScores.proportions,
            subScores.lighting,
            subScores.cleanliness,
            subScores.personality
        ]
    }

    private let labels = [
        String(localized: "radar_color"),
        String(localized: "radar_proportions"),
        String(localized: "radar_lighting"),
        String(localized: "radar_cleanliness"),
        String(localized: "radar_personality")
    ]

    private let icons = [
        "paintpalette.fill",
        "arrow.up.left.and.arrow.down.right",
        "sun.max.fill",
        "sparkles",
        "heart.fill"
    ]

    var body: some View {
        ZStack {
            gridLines
            axes
            dataShape
            labelViews
        }
        .frame(width: 220, height: 220)
        .padding(40)
        .padding(.top, 20)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    progress = 1
                }
                withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                    labelsVisible = true
                }
            } else {
                progress = 1
                labelsVisible = true
            }
        }
    }

    // MARK: - Grid

    private var gridLines: some View {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
            RadarShape(values: Array(repeating: Float(scale * 10), count: 5))
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        }
    }

    // MARK: - Axes

    private var axes: some View {
        ForEach(0..<5, id: \.self) { index in
            let angle = angleFor(index: index)
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: pointFor(angle: angle, radius: 1.0))
            }
            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            .offset(x: 110, y: 110)
        }
    }

    // MARK: - Data Shape

    private var dataShape: some View {
        ZStack {
            // Filled area with glow
            RadarShape(values: values)
                .fill(Color.rsAccent.opacity(0.15 * Double(progress)))

            // Glow layer
            RadarShape(values: values)
                .stroke(Color.rsAccent.opacity(0.4), lineWidth: 6)
                .blur(radius: 6)
                .opacity(Double(progress))

            // Crisp stroke
            RadarShape(values: values)
                .trim(from: 0, to: progress)
                .stroke(Color.rsAccent, lineWidth: 2)

            // Vertex dots
            ForEach(0..<5, id: \.self) { index in
                let angle = angleFor(index: index)
                let normalizedValue = CGFloat(values[index] / 10.0)
                let point = pointFor(angle: angle, radius: normalizedValue)

                Circle()
                    .fill(Color.rsAccent)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.rsAccent.opacity(0.6), radius: 4)
                    .offset(x: point.x, y: point.y)
                    .opacity(Double(progress))
            }
        }
    }

    // MARK: - Labels

    private var labelViews: some View {
        ForEach(0..<5, id: \.self) { index in
            let angle = angleFor(index: index)
            let point = pointFor(angle: angle, radius: 1.35)

            VStack(spacing: 3) {
                Image(systemName: icons[index])
                    .font(.system(size: 11))
                    .foregroundStyle(Color.scoreColor(for: values[index]))

                Text(labels[index])
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))

                Text(String(format: "%.1f", values[index]))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.scoreColor(for: values[index]))
            }
            .offset(x: point.x, y: point.y)
            .opacity(labelsVisible ? 1 : 0)
        }
    }

    // MARK: - Geometry

    private func angleFor(index: Int) -> Double {
        let slice = 2.0 * .pi / 5.0
        return slice * Double(index) - .pi / 2
    }

    private func pointFor(angle: Double, radius: Double) -> CGPoint {
        CGPoint(
            x: cos(angle) * 84 * radius,
            y: sin(angle) * 84 * radius
        )
    }
}

// MARK: - Radar Shape

private struct RadarShape: Shape {
    let values: [Float]

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.5
        let count = values.count

        var path = Path()

        for (index, value) in values.enumerated() {
            let angle = (2.0 * Double.pi / Double(count)) * Double(index) - Double.pi / 2
            let normalizedValue = CGFloat(value / 10.0)
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * normalizedValue,
                y: center.y + CGFloat(sin(angle)) * radius * normalizedValue
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        GradientBackground()
        RadarChartView(
            subScores: SubScores(
                colorHarmony: 5.5,
                proportions: 5.0,
                lighting: 6.0,
                cleanliness: 6.5,
                personality: 5.5
            )
        )
    }
    .padding()
}
