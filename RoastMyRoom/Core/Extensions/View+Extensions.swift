import SwiftUI

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalSize: CGSize = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalSize.width = max(totalSize.width, x - spacing)
            totalSize.height = max(totalSize.height, y + rowHeight)
        }

        return (positions, totalSize)
    }
}

// MARK: - Gradient Background

struct GradientBackground: View {
    @State private var cachedImage: UIImage? = GradientBackgroundCache.shared.image

    var body: some View {
        ZStack {
            Color.rsBgBase

            if let cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .ignoresSafeArea()
                    .opacity(0.15)
            }
        }
        .ignoresSafeArea()
        .task {
            if cachedImage == nil {
                let image = await GradientBackgroundCache.shared.render()
                cachedImage = image
            }
        }
    }
}

/// Renders the MeshGradient once and caches the result as a UIImage.
@MainActor
final class GradientBackgroundCache {
    static let shared = GradientBackgroundCache()
    private(set) var image: UIImage?

    func render() async -> UIImage? {
        if let image { return image }

        // Use a fixed size; the image is resizable and fills any screen
        let size = CGSize(width: 430, height: 932)
        let renderer = ImageRenderer(content:
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
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = 1.0
        let uiImage = renderer.uiImage
        image = uiImage
        return uiImage
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

// MARK: - Deferred View

/// Displays a lightweight placeholder on the first frame, then swaps to the real content.
/// Use this to prevent heavy views (NavigationStack, glass materials) from blocking tab transitions.
struct DeferredView<Content: View, Placeholder: View>: View {
    @State private var isReady = false
    let content: () -> Content
    let placeholder: () -> Placeholder

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        if isReady {
            content()
        } else {
            placeholder()
                .onAppear {
                    DispatchQueue.main.async {
                        isReady = true
                    }
                }
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

    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: radius)
                    .opacity(opacity)
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

// MARK: - Clear Navigation Controller Background

/// Clears the UIKit navigation controller's background color to prevent
/// black edges showing during fullScreenCover dismiss gestures.
struct ClearNavigationControllerBackground: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        Controller()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class Controller: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            view.backgroundColor = .clear
            navigationController?.view.backgroundColor = .clear
        }
    }
}

// MARK: - Clear Tab Bar Background

struct ClearTabBarBackground: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        Controller()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class Controller: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let tabBar = tabBarController?.tabBar else { return }
            tabBar.backgroundColor = .clear
            tabBar.barTintColor = .clear
            tabBar.isTranslucent = true
            tabBar.backgroundImage = UIImage()
            tabBar.shadowImage = UIImage()
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
            // Clear any opaque background subviews
            for subview in tabBar.subviews {
                if String(describing: type(of: subview)).contains("Background") {
                    subview.backgroundColor = .clear
                    subview.isHidden = true
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
