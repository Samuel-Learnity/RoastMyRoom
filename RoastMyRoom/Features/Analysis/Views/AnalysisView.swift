import SwiftUI

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: AnalysisViewModel
    var onResult: (ScanResult, UIImage) -> Void
    var onDismiss: () -> Void

    // Background
    @State private var blurRadius: CGFloat = 0
    @State private var photoScale: CGFloat = 1.0

    // Scope ring
    @State private var ringProgress: CGFloat = 0
    @State private var ringPulse: CGFloat = 1.0
    @State private var ringOpacity: Double = 0

    // Particles
    @State private var particleStart = Date.now

    // Completion
    @State private var showCompletionFlash = false

    // Guard
    @State private var hasStartedAnimations = false

    var body: some View {
        ZStack {
            backgroundLayer
            scanOverlayLayer
            particleLayer
            centralRingLayer

            if case .error(let message) = viewModel.state {
                errorContent(message: message)
            } else if case .analyzing = viewModel.state {
                stepIndicatorLayer
            }

            completionFlashLayer
        }
        .navigationBarBackButtonHidden()
        .task {
            guard !hasStartedAnimations else { return }
            hasStartedAnimations = true
            startAnimations()
            await viewModel.analyze(modelContext: modelContext)
        }
        .onChange(of: viewModel.currentStepIndex) { _, newIndex in
            withAnimation(.spring(duration: 0.6)) {
                ringProgress = CGFloat(newIndex + 1) / CGFloat(viewModel.steps.count)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Layer 1: Cinematic Background

    private var backgroundLayer: some View {
        Image(uiImage: viewModel.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .scaleEffect(photoScale)
            .blur(radius: blurRadius)
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.3), .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
    }

    // MARK: - Layer 2: Radial Scan Pulses

    private var scanOverlayLayer: some View {
        ZStack {
            scanPulseCircle(delay: 0)
            scanPulseCircle(delay: 1.5)
        }
        .allowsHitTesting(false)
    }

    private func scanPulseCircle(delay: Double) -> some View {
        Circle()
            .stroke(Color.rsAccent.opacity(0.2), lineWidth: 1.5)
            .frame(width: 200, height: 200)
            .modifier(PulseExpandModifier(delay: delay))
    }

    // MARK: - Layer 3: Floating Bokeh Particles

    private var particleLayer: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(particleStart)

            Canvas { context, size in
                for particle in Self.particles {
                    let t = CGFloat(elapsed)
                    let rawY = particle.initialY - (particle.speed * t)
                    let wrappedY = rawY.truncatingRemainder(dividingBy: 1.7)
                    let normalizedY = wrappedY < -0.2 ? wrappedY + 1.7 : wrappedY

                    let x = particle.x * size.width + sin(t * 0.5 + CGFloat(particle.id)) * 10
                    let y = normalizedY * size.height

                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                }
            }
        }
        .blur(radius: 2)
        .allowsHitTesting(false)
    }

    // MARK: - Layer 4: Central Scope Ring

    private var centralRingLayer: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(Color.rsAccent.opacity(0.12), lineWidth: 1)
                .frame(width: 180, height: 180)
                .scaleEffect(ringPulse)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)
                .frame(width: 160, height: 160)

            // Progress arc
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [Color.rsAccent.opacity(0.3), Color.rsAccent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            // Center icon
            Image(systemName: "viewfinder")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
                .symbolEffect(.pulse, options: .repeating)
        }
        .opacity(ringOpacity)
    }

    // MARK: - Layer 5: Step Indicators

    private var stepIndicatorLayer: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(viewModel.steps[viewModel.currentStepIndex])
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: viewModel.currentStepIndex)

            HStack(spacing: 24) {
                ForEach(0..<viewModel.steps.count, id: \.self) { index in
                    stepIcon(for: index)
                }
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }

    private func stepIcon(for index: Int) -> some View {
        let isCompleted = index < viewModel.currentStepIndex
        let isActive = index == viewModel.currentStepIndex
        let iconNames = [
            "paintpalette.fill",
            "wand.and.stars",
            "square.grid.3x3.topleft.filled",
            "chart.bar.fill"
        ]

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isCompleted
                            ? Color.rsAccent
                            : (isActive ? Color.rsAccent.opacity(0.2) : Color.white.opacity(0.08))
                    )
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: iconNames[index])
                        .font(.system(size: 18))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.3))
                        .symbolEffect(.bounce, value: isActive ? viewModel.currentStepIndex : -1)
                }
            }
            .animation(.spring(duration: 0.4), value: viewModel.currentStepIndex)

            Circle()
                .fill(isCompleted || isActive ? Color.rsAccent : Color.white.opacity(0.15))
                .frame(width: 6, height: 6)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStepIndex)
        }
    }

    // MARK: - Layer 6: Completion Flash

    private var completionFlashLayer: some View {
        Color.white
            .ignoresSafeArea()
            .opacity(showCompletionFlash ? 0.4 : 0)
            .allowsHitTesting(false)
    }

    // MARK: - Error State

    private func errorContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.white)

            Text(message)
                .font(.body)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(String(localized: "analysis_retry")) {
                    Task { await viewModel.retry(modelContext: modelContext) }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.rsAccent)

                Button(String(localized: "analysis_cancel")) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
        }
        .padding(24)
        .glassBackground()
    }

    // MARK: - Animation Helpers

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4.0)) {
            blurRadius = 20
            photoScale = 1.08
        }

        withAnimation(.easeIn(duration: 0.5)) {
            ringOpacity = 1
        }

        withAnimation(.spring(duration: 0.6)) {
            ringProgress = 1.0 / CGFloat(viewModel.steps.count)
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            ringPulse = 1.06
        }
    }

    private func handleStateChange(_ newState: AnalysisViewModel.State) {
        switch newState {
        case .success(let result):
            withAnimation(.spring(duration: 0.3)) {
                ringProgress = 1.0
            }

            withAnimation(.easeIn(duration: 0.15)) {
                showCompletionFlash = true
            }

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeOut(duration: 0.15)) {
                    showCompletionFlash = false
                }
                try? await Task.sleep(for: .milliseconds(200))
                onResult(result, viewModel.image)
            }

        case .error:
            withAnimation(.easeOut(duration: 0.3)) {
                ringOpacity = 0
            }

        case .analyzing:
            break
        }
    }
}

// MARK: - Particle Data

private extension AnalysisView {
    struct BokehParticle {
        let id: Int
        let x: CGFloat
        let initialY: CGFloat
        let speed: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    static let particles: [BokehParticle] = {
        var rng = SeededRandomNumberGenerator(seed: 42)
        return (0..<14).map { i in
            BokehParticle(
                id: i,
                x: CGFloat.random(in: 0...1, using: &rng),
                initialY: CGFloat.random(in: 0.3...1.5, using: &rng),
                speed: CGFloat.random(in: 0.04...0.10, using: &rng),
                size: CGFloat.random(in: 4...12, using: &rng),
                opacity: Double.random(in: 0.08...0.25, using: &rng)
            )
        }
    }()
}

// MARK: - Seeded RNG (deterministic particles for consistency)

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Pulse Expand Modifier

private struct PulseExpandModifier: ViewModifier {
    let delay: Double
    @State private var isExpanded = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isExpanded ? 4.0 : 0.5)
            .opacity(isExpanded ? 0 : 0.8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        .easeOut(duration: 3.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        isExpanded = true
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    AnalysisView(
        viewModel: AnalysisViewModel(
            image: UIImage(systemName: "photo")!,
            scoringService: MockScoringService(),
            storageService: StorageService()
        ),
        onResult: { _, _ in },
        onDismiss: { }
    )
}
