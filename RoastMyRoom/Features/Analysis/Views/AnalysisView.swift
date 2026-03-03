import SwiftUI

struct AnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: AnalysisViewModel
    var onResult: (ScanResult, UIImage, RoomScan?) -> Void
    var onDismiss: () -> Void

    // Background
    @State private var blurRadius: CGFloat = 0
    @State private var photoScale: CGFloat = 1.0

    // Neon ring
    @State private var ringProgress: CGFloat = 0
    @State private var ringOpacity: Double = 0

    // Percentage
    @State private var displayedPercent: Int = 0

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
            let stepFraction = CGFloat(newIndex + 1) / CGFloat(viewModel.steps.count)
            let duration = 0.8 - (Double(newIndex) * 0.1)

            withAnimation(.spring(duration: duration)) {
                ringProgress = stepFraction
            }

            let stepPercents = [10, 40, 70, 92]
            displayedPercent = stepPercents[min(newIndex, stepPercents.count - 1)]
        }
        .onChange(of: viewModel.state) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Layer 1: Cinematic Background

    private var backgroundLayer: some View {
        Image(uiImage: viewModel.displayImage)
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

    // MARK: - Layer 2: Radial Scan Ambient

    private var scanOverlayLayer: some View {
        RadialGradient(
            colors: [
                Color.aiPurple.opacity(0.12),
                Color.aiLightBlue.opacity(0.06),
                .clear
            ],
            center: .center,
            startRadius: 40,
            endRadius: 300
        )
        .allowsHitTesting(false)
    }

    // MARK: - Layer 3: Floating Neon Particles

    private var particleLayer: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(particleStart)

            Canvas { context, size in
                let aiColors: [Color] = Color.aiNeonPalette

                for particle in Self.particles {
                    let t = CGFloat(elapsed)
                    let rawY = particle.initialY - (particle.speed * t)
                    let wrappedY = rawY.truncatingRemainder(dividingBy: 1.7)
                    let normalizedY = wrappedY < -0.2 ? wrappedY + 1.7 : wrappedY

                    let x = particle.x * size.width + sin(t * 0.5 + CGFloat(particle.id)) * 10
                    let y = normalizedY * size.height

                    // Variable Reward: occasional sparkle pop (~15% of the time)
                    let sparkle = sin(t * 1.8 + particle.sparklePhase)
                    let sparkleBoost: CGFloat = sparkle > 0.85 ? 1.8 : 1.0
                    let currentSize = particle.size * sparkleBoost
                    let currentOpacity = particle.opacity * Double(sparkleBoost)

                    let rect = CGRect(
                        x: x - currentSize / 2,
                        y: y - currentSize / 2,
                        width: currentSize,
                        height: currentSize
                    )

                    context.opacity = currentOpacity
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(aiColors[particle.colorIndex % aiColors.count])
                    )
                }
            }
        }
        .blur(radius: 2)
        .allowsHitTesting(false)
    }

    // MARK: - Layer 4: Apple Intelligence Neon Ring

    private let neonGradient = AngularGradient(
        colors: Color.aiNeonPalette,
        center: .center
    )

    private var centralRingLayer: some View {
        ZStack {
            // Merged glow (single blur pass)
            Circle()
                .stroke(neonGradient, lineWidth: 16)
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .opacity(0.4)

            // Track ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 4)
                .frame(width: 160, height: 160)

            // Progress arc + neon halo (single arc, shadow for glow)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    neonGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .shadow(color: .aiPurple.opacity(0.6), radius: 8)

            // Percentage counter
            percentageCounter
        }
        .opacity(ringOpacity)
    }

    // MARK: - Percentage Counter

    private var percentageCounter: some View {
        VStack(spacing: 2) {
            Text("\(displayedPercent)%")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(displayedPercent)))
                .animation(.spring(duration: 0.6), value: displayedPercent)

            Text(String(localized: "analysis_processing"))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.5)
        }
    }

    // MARK: - Layer 5: Step Indicators (connected track)

    private let stepColors: [Color] = [.aiPurple, .aiPink, .aiLightBlue, .aiCoral]

    private enum StepLayout {
        static let iconSize: CGFloat = 36
        static let connectorWidth: CGFloat = 32
        static let trackHeight: CGFloat = 2
        static let glowBlurRadius: CGFloat = 12
    }

    private let stepIconNames = [
        "brain.head.profile.fill",
        "wand.and.stars",
        "square.grid.3x3.topleft.filled",
        "chart.bar.fill"
    ]

    private var stepIndicatorLayer: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(viewModel.steps[viewModel.currentStepIndex])
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: viewModel.currentStepIndex)

            stepTrackWithIcons
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }

    private var stepTrackWithIcons: some View {
        let stepCount = viewModel.steps.count

        return HStack(spacing: 0) {
            ForEach(0..<stepCount, id: \.self) { index in
                stepCircle(for: index)
                if index < stepCount - 1 {
                    stepConnector(at: index)
                }
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.15), value: viewModel.currentStepIndex)
    }

    private func stepConnector(at index: Int) -> some View {
        let isFilled = viewModel.currentStepIndex > index
        let gradient = LinearGradient(
            colors: [stepColors[index], stepColors[index + 1]],
            startPoint: .leading,
            endPoint: .trailing
        )

        return ZStack {
            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(width: StepLayout.connectorWidth, height: StepLayout.trackHeight)

            Capsule()
                .fill(gradient)
                .frame(width: StepLayout.connectorWidth, height: StepLayout.trackHeight)
                .blur(radius: StepLayout.glowBlurRadius)
                .opacity(isFilled ? 0.6 : 0)

            Capsule()
                .fill(gradient)
                .frame(width: StepLayout.connectorWidth, height: StepLayout.trackHeight)
                .opacity(isFilled ? 1 : 0)
        }
    }

    private func stepCircle(for index: Int) -> some View {
        let isCompleted = index < viewModel.currentStepIndex
        let isActive = index == viewModel.currentStepIndex
        let color = stepColors[index]

        return Group {
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: stepIconNames[index])
                    .font(.system(size: 15))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.25))
                    .symbolEffect(.bounce, value: isActive ? viewModel.currentStepIndex : -1)
            }
        }
        .frame(width: StepLayout.iconSize, height: StepLayout.iconSize)
        .glassEffect(.regular.interactive(), in: .circle)
        .tint(isCompleted || isActive ? color : .white.opacity(0.15))
        .animation(.spring(duration: 0.4), value: viewModel.currentStepIndex)
    }

    // MARK: - Layer 6: Completion Flash (AI tinted)

    private var completionFlashLayer: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .opacity(showCompletionFlash ? 0.3 : 0)

            RadialGradient(
                colors: [Color.aiPurple.opacity(0.3), Color.aiLightBlue.opacity(0.1), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(showCompletionFlash ? 0.5 : 0)
        }
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
        // Cinematic background zoom + blur
        withAnimation(.easeInOut(duration: 4.0)) {
            blurRadius = 20
            photoScale = 1.08
        }

        // Ring fade in
        withAnimation(.easeIn(duration: 0.5)) {
            ringOpacity = 1
        }

        // Initial progress (first step)
        withAnimation(.spring(duration: 0.6)) {
            ringProgress = 1.0 / CGFloat(viewModel.steps.count)
        }
    }

    private func handleStateChange(_ newState: AnalysisViewModel.State) {
        switch newState {
        case .success(let result, let scan):
            // Snap ring + percent to full (Peak-End Rule)
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                ringProgress = 1.0
            }
            displayedPercent = 100

            // Flash
            withAnimation(.easeIn(duration: 0.12)) {
                showCompletionFlash = true
            }

            Task {
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.2)) {
                    showCompletionFlash = false
                }
                try? await Task.sleep(for: .milliseconds(300))
                onResult(result, viewModel.displayImage, scan)
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
        let colorIndex: Int
        let sparklePhase: CGFloat
    }

    static let particles: [BokehParticle] = {
        var rng = SeededRandomNumberGenerator(seed: 42)
        let paletteCount = 7
        return (0..<18).map { i in
            BokehParticle(
                id: i,
                x: CGFloat.random(in: 0...1, using: &rng),
                initialY: CGFloat.random(in: 0.3...1.5, using: &rng),
                speed: CGFloat.random(in: 0.04...0.10, using: &rng),
                size: CGFloat.random(in: 4...14, using: &rng),
                opacity: Double.random(in: 0.10...0.30, using: &rng),
                colorIndex: Int.random(in: 0..<paletteCount, using: &rng),
                sparklePhase: CGFloat.random(in: 0...6.28, using: &rng)
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

// MARK: - Preview

#Preview {
    AnalysisView(
        viewModel: AnalysisViewModel(
            image: UIImage(systemName: "photo")!,
            scoringService: MockScoringService(),
            storageService: StorageService()
        ),
        onResult: { _, _, _ in },
        onDismiss: { }
    )
}
