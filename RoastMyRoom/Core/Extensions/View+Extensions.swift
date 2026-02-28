import SwiftUI

// MARK: - Gradient Background

struct GradientBackground: View {
    var body: some View {
        ZStack {
            Color.rsBgBase

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .aiDeepPurple, .aiLightBlue, .aiPurple,
                    .aiPink,       .aiLavender,  .aiCoral,
                    .aiPurple,     .aiPeach,     .aiDeepPurple
                ]
            )
            .opacity(0.15)
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Modifiers

extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.rsCardStroke, lineWidth: 1)
            )
    }

    func gradientBackground() -> some View {
        self.background { GradientBackground() }
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

    /// Apple Intelligence–inspired glow: animated gradient aura as the button background,
    /// with a subtle glass blur on top. No solid fill — the glow IS the background.
    func aiGlow(
        colors: [Color] = [.purple, Color.rsAccent, .cyan, .pink],
        cornerRadius: CGFloat = 16,
        glowRadius: CGFloat = 12,
        glowOpacity: Double = 0.8
    ) -> some View {
        self.modifier(AIGlowModifier(
            colors: colors,
            cornerRadius: cornerRadius,
            glowRadius: glowRadius,
            glowOpacity: glowOpacity
        ))
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

// MARK: - AI Glow (Apple Intelligence style)

private struct AIGlowModifier: ViewModifier {
    let colors: [Color]
    let cornerRadius: CGFloat
    let glowRadius: CGFloat
    let glowOpacity: Double
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Outer diffused glow — spreads beyond the button
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            AngularGradient(
                                colors: colors + [colors.first ?? .purple],
                                center: .center,
                                startAngle: .degrees(Double(phase) * 360),
                                endAngle: .degrees(Double(phase) * 360 + 360)
                            )
                        )
                        .blur(radius: glowRadius + 8)
                        .opacity(glowOpacity * 0.6)
                        .scaleEffect(1.15)

                    // Inner glow — tighter, more saturated
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            AngularGradient(
                                colors: colors + [colors.first ?? .purple],
                                center: .center,
                                startAngle: .degrees(Double(phase) * 360 + 60),
                                endAngle: .degrees(Double(phase) * 360 + 420)
                            )
                        )
                        .blur(radius: glowRadius)
                        .opacity(glowOpacity)

                    // Glass layer — subtle frosted surface
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)

                    // Thin bright border tracing the glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            AngularGradient(
                                colors: colors + [colors.first ?? .purple],
                                center: .center,
                                startAngle: .degrees(Double(phase) * 360),
                                endAngle: .degrees(Double(phase) * 360 + 360)
                            ),
                            lineWidth: 1.5
                        )
                        .opacity(0.7)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 4)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
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
