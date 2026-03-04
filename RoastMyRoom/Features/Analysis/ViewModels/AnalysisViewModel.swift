import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class AnalysisViewModel {
    enum State: Equatable {
        case analyzing
        case success(ScanResult, RoomScan?)
        case error(String)
    }

    private(set) var state: State = .analyzing
    private(set) var currentStepIndex = 0
    private var hasStartedAnalysis = false

    let image: UIImage
    private(set) var displayImage: UIImage
    private let scoringService: ScoringServiceProtocol
    private let storageService: StorageServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol

    let steps: [String] = [
        String(localized: "analysis_step_neural"),
        String(localized: "analysis_step_deep"),
        String(localized: "analysis_step_spatial"),
        String(localized: "analysis_step_scoring")
    ]

    init(image: UIImage, scoringService: ScoringServiceProtocol, storageService: StorageServiceProtocol, analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.image = image
        self.displayImage = image
        self.scoringService = scoringService
        self.storageService = storageService
        self.analyticsService = analyticsService
    }

    func analyze(modelContext: ModelContext) async {
        guard !hasStartedAnalysis else { return }
        hasStartedAnalysis = true
        analyticsService.track(.analysisStarted())

        // Downscale for display/storage (original kept for API)
        let original = image
        displayImage = await Task.detached {
            original.resized(maxWidth: 1280, maxHeight: 960)
        }.value

        let startTime = ContinuousClock.now

        // Escalating haptic styles per step (Anticipation bias)
        let hapticStyles: [UIImpactFeedbackGenerator.FeedbackStyle] = [
            .medium, .rigid, .heavy
        ]

        // Start step rotation with escalating haptics
        let stepTask = Task {
            for index in 1..<steps.count {
                try await Task.sleep(for: .milliseconds(800))
                currentStepIndex = index
                UIImpactFeedbackGenerator(style: hapticStyles[index - 1]).impactOccurred()
            }
        }

        // Call API
        do {
            let result = try await scoringService.scoreRoom(image: image)

            // Ensure minimum 2.5s display
            let elapsed = ContinuousClock.now - startTime
            let remaining = Duration.milliseconds(2500) - elapsed
            if remaining > .zero {
                try? await Task.sleep(for: remaining)
            }

            stepTask.cancel()
            currentStepIndex = steps.count - 1

            // Peak-End Rule: spectacular completion haptic burst
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(100))
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            // Auto-save to SwiftData (compress off main thread)
            let downscaled = displayImage
            let imageData = await Task.detached {
                downscaled.jpegData(compressionQuality: 0.8)
            }.value
            var savedScan: RoomScan?
            if let imageData {
                let scan = RoomScan(from: result, imageData: imageData)
                storageService.save(scan, in: modelContext)
                savedScan = scan
            }

            // Brief pause to let user see the completed state
            try? await Task.sleep(for: .milliseconds(600))

            let durationMs = Int((ContinuousClock.now - startTime).components.seconds * 1000)
            analyticsService.track(.analysisSuccess(
                score: Double(result.overallScore),
                style: result.style,
                durationMs: durationMs
            ))

            state = .success(result, savedScan)
        } catch {
            stepTask.cancel()
            #if DEBUG
            print("[AnalysisVM] Analysis failed: \(error)")
            #endif
            analyticsService.track(.analysisError(error: error.localizedDescription))
            state = .error(error.localizedDescription)
        }
    }

    func retry(modelContext: ModelContext) async {
        state = .analyzing
        currentStepIndex = 0
        hasStartedAnalysis = false
        await analyze(modelContext: modelContext)
    }
}
