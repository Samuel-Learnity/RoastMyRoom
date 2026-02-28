import SwiftUI

struct ScanView: View {
    @State var viewModel: ScanViewModel
    let subscriptionService: SubscriptionService
    var cameraAccessory: CameraAccessoryState
    @State private var showGuide = true
    @State private var showScanLimitPaywall = false
    @State private var capturedPhoto: CapturedPhoto?

    var body: some View {
        NavigationStack {
            ZStack {
                cameraLayer
                controlsOverlay

                guideOverlay
            }
            .ignoresSafeArea(edges: .all)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleFlash()
                    } label: {
                        Image(systemName: viewModel.flashIcon)
                    }
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .task {
                if viewModel.cameraPermission == .notDetermined {
                    await viewModel.requestCameraPermission()
                }
                viewModel.setupAndStartCamera()
                syncCameraToAccessory()
            }
            .onChange(of: viewModel.capturedImage) { _, newImage in
                guard let image = newImage else { return }
                viewModel.capturedImage = nil

                if !subscriptionService.canScan {
                    showScanLimitPaywall = true
                    return
                }

                capturedPhoto = CapturedPhoto(image: image)
            }
            .onChange(of: viewModel.availableLenses) { _, lenses in
                cameraAccessory.availableLenses = lenses
            }
            .onChange(of: viewModel.activeLensIndex) { _, index in
                cameraAccessory.activeLensIndex = index
            }
            .sheet(isPresented: $showScanLimitPaywall) {
                PaywallView(
                    viewModel: AppFactory.shared.makePaywallViewModel(),
                    backgroundImage: nil,
                    score: nil
                )
                .presentationDetents([.large])
            }
            .fullScreenCover(item: $capturedPhoto) { captured in
                ScanFlowView(
                    image: captured.image,
                    subscriptionService: subscriptionService,
                    onDismiss: {
                        capturedPhoto = nil
                    }
                )
            }
        }
    }

    // MARK: - Camera Layer

    @ViewBuilder
    private var cameraLayer: some View {
        switch viewModel.cameraPermission {
        case .authorized:
            CameraPreview(session: viewModel.captureSession)
                .containerRelativeFrame([.horizontal, .vertical])
        case .denied:
            deniedView
        case .notDetermined:
            Color.black
                .containerRelativeFrame([.horizontal, .vertical])
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack {
            HStack {
                // Remaining scans indicator
                if !subscriptionService.isPremium {
                    VStack(alignment: .leading, spacing: 4) {
                        let remaining = subscriptionService.remainingScansToday
                        Text(String(localized: "scan_remaining \(remaining)"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        if subscriptionService.pointsBalance > 0 {
                            Text(String(localized: "scan_points_balance \(subscriptionService.pointsBalance)"))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rsAccent)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.leading, 20)
                    .padding(.top, 60)
                }

                Spacer()
            }

            Spacer()

            // Provocative CTA wording
            VStack(spacing: 8) {
                Text(String(localized: "scan_cta_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(localized: "scan_cta_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .shadow(color: .black.opacity(0.6), radius: 8, y: 2)

            Spacer()
        }
    }

    private func syncCameraToAccessory() {
        cameraAccessory.availableLenses = viewModel.availableLenses
        cameraAccessory.activeLensIndex = viewModel.activeLensIndex
        cameraAccessory.onCapture = { [viewModel] in
            viewModel.capturePhoto()
        }
        cameraAccessory.onSwitchLens = { [viewModel] index in
            viewModel.switchToLens(at: index)
        }
        cameraAccessory.onPickedImage = { [viewModel] image in
            viewModel.handlePickedImage(image)
        }
    }

    // MARK: - Guide

    private var guideOverlay: some View {
        VStack {
            Spacer()
            Text(String(localized: "scan_guide"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.black.opacity(0.5), in: Capsule())
                .padding(.bottom, 140)
        }
        .frame(maxWidth: .infinity)
        .opacity(showGuide ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(2)) {
                showGuide = false
            }
        }
    }

    // MARK: - Denied

    private var deniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(String(localized: "camera_denied_title"))
                .font(.title3)
                .fontWeight(.semibold)

            Text(String(localized: "camera_denied_message"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(String(localized: "camera_denied_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.rsAccent)
        }
    }
}

// MARK: - Navigation Route Types

struct CapturedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ScanResultRoute: Identifiable, Hashable {
    let id = UUID()
    let result: ScanResult
    let image: UIImage

    static func == (lhs: ScanResultRoute, rhs: ScanResultRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Scan Flow (fullScreenCover: Analysis → Result)

private struct ScanFlowView: View {
    let image: UIImage
    let subscriptionService: SubscriptionService
    var onDismiss: () -> Void
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AnalysisView(
                viewModel: AppFactory.shared.makeAnalysisViewModel(image: image),
                onResult: { result, img in
                    _ = subscriptionService.recordScanWithSource()
                    path.append(ScanResultRoute(result: result, image: img))
                },
                onDismiss: onDismiss
            )
            .navigationDestination(for: ScanResultRoute.self) { route in
                ResultView(
                    viewModel: AppFactory.shared.makeResultViewModel(
                        scanResult: route.result,
                        image: route.image,
                        isPremium: subscriptionService.isPremium
                    ),
                    subscriptionService: subscriptionService,
                    onDismiss: onDismiss
                )
            }
        }
    }
}

#Preview {
    ScanView(viewModel: ScanViewModel(), subscriptionService: SubscriptionService(), cameraAccessory: CameraAccessoryState())
}
