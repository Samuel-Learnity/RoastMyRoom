import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class AnalysisViewModel {
    enum State: Equatable {
        case analyzing
        case success(ScanResult)
        case error(String)
    }

    private(set) var state: State = .analyzing
    private(set) var currentStepIndex = 0
    private(set) var analysisPercent: Int = 0
    private var hasStartedAnalysis = false

    let image: UIImage
    private let scoringService: ScoringServiceProtocol
    private let storageService: StorageServiceProtocol

    let steps: [String] = [
        String(localized: "analysis_step_neural"),
        String(localized: "analysis_step_deep"),
        String(localized: "analysis_step_spatial"),
        String(localized: "analysis_step_scoring")
    ]

    init(image: UIImage, scoringService: ScoringServiceProtocol, storageService: StorageServiceProtocol) {
        self.image = image
        self.scoringService = scoringService
        self.storageService = storageService
    }

    func analyze(modelContext: ModelContext) async {
        guard !hasStartedAnalysis else { return }
        hasStartedAnalysis = true

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

        // Goal Gradient: percentage accelerates toward the end
        let percentTask = Task {
            for i in 1...95 {
                let progress = Double(i) / 95.0
                let delay = 26.0 - (progress * 8.0) // 26ms early → 18ms late
                try await Task.sleep(for: .milliseconds(Int(delay)))
                analysisPercent = i
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
            percentTask.cancel()
            analysisPercent = 100

            // Peak-End Rule: spectacular completion haptic burst
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            try? await Task.sleep(for: .milliseconds(100))
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            // Auto-save to SwiftData (compress off main thread)
            let capturedImage = image
            let imageData = await Task.detached {
                capturedImage.jpegData(compressionQuality: 0.8)
            }.value
            if let imageData {
                let scan = RoomScan(from: result, imageData: imageData)
                storageService.save(scan, in: modelContext)
            }

            state = .success(result)
        } catch {
            stepTask.cancel()
            percentTask.cancel()
            print("[AnalysisVM] Analysis failed: \(error)")
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
