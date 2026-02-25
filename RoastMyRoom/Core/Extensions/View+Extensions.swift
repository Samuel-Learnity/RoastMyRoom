import SwiftUI

extension View {
    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    func shimmer(isActive: Bool) -> some View {
        if isActive {
            self.modifier(ShimmerModifier())
        } else {
            self
        }
    }
}

// MARK: - Neon Glow

extension View {
    func neonGlow(
        colors: [Color] = [.purple, Color.rsAccent, .pink],
        radius: CGFloat = 16,
        opacity: Double = 0.7
    ) -> some View {
        self.modifier(NeonGlowModifier(colors: colors, radius: radius, opacity: opacity))
    }
}

private struct NeonGlowModifier: ViewModifier {
    let colors: [Color]
    let radius: CGFloat
    let opacity: Double
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background {
                // Animated gradient glow behind the view
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .init(x: phase, y: 0),
                            endPoint: .init(x: phase + 1, y: 1)
                        )
                    )
                    .blur(radius: radius)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 3)
                            .repeatForever(autoreverses: true)
                        ) {
                            phase = 1
                        }
                    }
            }
    }
}

// MARK: - Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}
