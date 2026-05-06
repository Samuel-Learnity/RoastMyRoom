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
        opacity: Double = 0.7,
        duration: Double? = nil
    ) -> some View {
        self.modifier(NeonGlowModifier(colors: colors, radius: radius, opacity: opacity, duration: duration))
    }
}

private struct NeonGlowModifier: ViewModifier {
    let colors: [Color]
    let radius: CGFloat
    let opacity: Double
    let duration: Double?
    @State private var visible = true

    func body(content: Content) -> some View {
        content
            .background {
                if visible {
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
                        .transition(.opacity)
                }
            }
            .task(id: duration) {
                guard let duration else { return }
                try? await Task.sleep(for: .seconds(duration))
                withAnimation(.easeOut(duration: 1.5)) {
                    visible = false
                }
            }
    }
}

// MARK: - AI Glow (Apple Intelligence style)

extension View {
    func aiGlow(
        colors: [Color] = [.purple, Color.rsAccent, .cyan, .pink],
        cornerRadius: CGFloat = 16,
        glowRadius: CGFloat = 12,
        glowOpacity: Double = 0.8,
        duration: Double? = nil
    ) -> some View {
        self.modifier(AIGlowModifier(
            colors: colors,
            cornerRadius: cornerRadius,
            glowRadius: glowRadius,
            glowOpacity: glowOpacity,
            duration: duration
        ))
    }
}

private struct AIGlowModifier: ViewModifier {
    let colors: [Color]
    let cornerRadius: CGFloat
    let glowRadius: CGFloat
    let glowOpacity: Double
    let duration: Double?
    @State private var phase: CGFloat = 0
    @State private var visible = true

    func body(content: Content) -> some View {
        content
            .background {
                if visible {
                    ZStack {
                        // Outer diffused glow -> spreads beyond the button
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

                        // Inner glow -> tighter, more saturated
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

                        // Glass layer -> subtle frosted surface
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
                    .transition(.opacity)
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
            .task(id: duration) {
                guard let duration else { return }
                try? await Task.sleep(for: .seconds(duration))
                withAnimation(.easeOut(duration: 1.5)) {
                    visible = false
                }
            }
    }
}

// MARK: - Previews

#Preview("AI Glow") {
    VStack(spacing: 32) {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.rsAccent)
                Text("paywall_bullet_unlimited_scans")
                    .font(.body)
                    .foregroundStyle(.white)
            }
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.rsAccent)
                Text("paywall_bullet_radar")
                    .font(.body)
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aiGlow(colors: [.purple.opacity(0.6), Color.rsAccent.opacity(0.5), .cyan.opacity(0.4)], cornerRadius: 20, glowRadius: 8, glowOpacity: 0.3)
        .padding(20)
        
        Text("Buy 10 points, get 1 free")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .aiGlow()

        Text("✨ Analyze")
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .aiGlow(cornerRadius: 28)
            .padding(.horizontal, 40)

        Circle()
            .fill(.clear)
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "camera.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .aiGlow(cornerRadius: 40, glowRadius: 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.rsBgBase)
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
