import SwiftUI
import AVFoundation
import PhotosUI
import Observation

@MainActor
@Observable
final class ScanViewModel {
    enum CameraPermission {
        case notDetermined
        case authorized
        case denied
    }

    private(set) var cameraPermission: CameraPermission = .notDetermined
    var capturedImage: UIImage?
    var showPhotoPicker = false
    var flashMode: AVCaptureDevice.FlashMode = .auto

    // MARK: - Lens

    struct Lens: Identifiable, Equatable {
        let id: AVCaptureDevice.DeviceType
        let label: String  // "0.5×", "1×", "2×"
        let device: AVCaptureDevice

        static func == (lhs: Lens, rhs: Lens) -> Bool { lhs.id == rhs.id }
    }

    private(set) var availableLenses: [Lens] = []
    private(set) var activeLensIndex: Int = 0

    // MARK: - Camera Session

    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var currentInput: AVCaptureDeviceInput?
    private var isSessionConfigured = false
    private let analyticsService: AnalyticsServiceProtocol

    // MARK: - Init

    init(analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.analyticsService = analyticsService
        checkCameraPermission()
    }

    // MARK: - Permissions

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .authorized
        case .notDetermined:
            cameraPermission = .notDetermined
        default:
            cameraPermission = .denied
        }
    }

    func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermission = granted ? .authorized : .denied
        analyticsService.track(.cameraPermissionResult(granted: granted))
    }

    // MARK: - Session Management

    func setupAndStartCamera() {
        guard cameraPermission == .authorized else { return }

        if !isSessionConfigured {
            discoverLenses()
        }

        let needsSetup = !isSessionConfigured

        // Pick default lens: ultra-wide if available, else wide
        let defaultIndex: Int
        if let uwIndex = availableLenses.firstIndex(where: { $0.id == .builtInUltraWideCamera }) {
            defaultIndex = uwIndex
        } else {
            defaultIndex = 0
        }
        let defaultDevice = availableLenses.isEmpty ? nil : availableLenses[defaultIndex].device

        Task {
            let input = await SessionHelper.setupAndStart(
                session: captureSession,
                output: photoOutput,
                needsSetup: needsSetup,
                defaultDevice: defaultDevice
            )
            if let input {
                currentInput = input
                activeLensIndex = defaultIndex
            }
        }

        isSessionConfigured = true
    }

    private func discoverLenses() {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInUltraWideCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]

        let labels: [AVCaptureDevice.DeviceType: String] = [
            .builtInUltraWideCamera: "0.5×",
            .builtInWideAngleCamera: "1×",
            .builtInTelephotoCamera: "2×"
        ]

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )

        // Deduplicate by device type, keep order
        var seen = Set<AVCaptureDevice.DeviceType>()
        var lenses: [Lens] = []

        for deviceType in deviceTypes {
            if let device = discovery.devices.first(where: { $0.deviceType == deviceType }),
               !seen.contains(deviceType) {
                seen.insert(deviceType)
                lenses.append(Lens(
                    id: deviceType,
                    label: labels[deviceType] ?? "?",
                    device: device
                ))
            }
        }

        availableLenses = lenses
    }

    func stopSession() {
        Task {
            await SessionHelper.stop(session: captureSession)
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode

        let delegate = PhotoCaptureDelegate { [weak self] image in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.capturedImage = image
            }
        }
        photoCaptureDelegate = delegate
        photoOutput.capturePhoto(with: settings, delegate: delegate)
        analyticsService.track(.scanPhotoCaptured(source: "camera"))

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // MARK: - Lens Switching

    func switchToLens(at index: Int) {
        guard index >= 0, index < availableLenses.count, index != activeLensIndex else { return }

        let oldInput = currentInput
        let newDevice = availableLenses[index].device
        let targetIndex = index

        Task {
            let newInput = await SessionHelper.switchLens(
                session: captureSession,
                oldInput: oldInput,
                newDevice: newDevice
            )
            if let newInput {
                currentInput = newInput
                activeLensIndex = targetIndex
            }
        }

        analyticsService.track(.scanLensSwitched(lens: availableLenses[index].label))

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // MARK: - Flash

    func toggleFlash() {
        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
        analyticsService.track(.scanFlashChanged(mode: flashIcon))
    }

    var flashIcon: String {
        switch flashMode {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        @unknown default: return "bolt.badge.automatic"
        }
    }

    // MARK: - Gallery

    func handlePickedImage(_ image: UIImage?) {
        capturedImage = image
        if image != nil {
            analyticsService.track(.scanPhotoCaptured(source: "gallery"))
        }
    }
}

// MARK: - Session Helper (nonisolated for Swift 6 concurrency)

private enum SessionHelper {
    nonisolated static func setupAndStart(
        session: AVCaptureSession,
        output: AVCapturePhotoOutput,
        needsSetup: Bool,
        defaultDevice: AVCaptureDevice?
    ) async -> AVCaptureDeviceInput? {
        var resultInput: AVCaptureDeviceInput?

        if needsSetup {
            session.beginConfiguration()
            session.sessionPreset = .photo

            if let device = defaultDevice,
               let input = try? AVCaptureDeviceInput(device: device) {
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                resultInput = input
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
        }

        if !session.isRunning {
            session.startRunning()
        }

        return resultInput
    }

    nonisolated static func stop(session: AVCaptureSession) async {
        if session.isRunning {
            session.stopRunning()
        }
    }

    nonisolated static func switchLens(
        session: AVCaptureSession,
        oldInput: AVCaptureDeviceInput?,
        newDevice: AVCaptureDevice
    ) async -> AVCaptureDeviceInput? {
        guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return nil }

        session.beginConfiguration()
        if let oldInput {
            session.removeInput(oldInput)
        }
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        session.commitConfiguration()

        return newInput
    }
}

// MARK: - Photo Capture Delegate

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: @Sendable (UIImage?) -> Void

    init(completion: @escaping @Sendable (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        // Downscale off main thread to avoid UI freeze on navigation
        let downsized = image.resized(maxWidth: 1536, maxHeight: 1152)
        completion(downsized)
    }
}
