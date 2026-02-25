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
    private var hasStartedAnalysis = false

    let image: UIImage
    private let scoringService: ScoringServiceProtocol
    private let storageService: StorageServiceProtocol

    let steps: [String] = [
        String(localized: "analysis_step_colors"),
        String(localized: "analysis_step_style"),
        String(localized: "analysis_step_layout"),
        String(localized: "analysis_step_score")
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

        // Start step rotation
        let stepTask = Task {
            for index in 1..<steps.count {
                try await Task.sleep(for: .milliseconds(800))
                currentStepIndex = index
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
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
            print("[AnalysisVM] ❌ Analysis failed: \(error)")
            print("[AnalysisVM] Error type: \(type(of: error))")
            print("[AnalysisVM] Localized: \(error.localizedDescription)")
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
