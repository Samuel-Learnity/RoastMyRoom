import SwiftUI

struct ScanView: View {
    @State var viewModel: ScanViewModel
    let subscriptionService: SubscriptionServiceProtocol
    var cameraAccessory: CameraAccessoryState
    @State private var showCTA = false
    @State private var ctaHideTask: Task<Void, Never>?
    @State private var paywallViewModel: PaywallViewModel?
    @State private var capturedPhoto: CapturedPhoto?
    @State private var capsuleScale: CGFloat = 1.0
    @State private var capsuleGold = false
    @State private var capsuleShake: CGFloat = 0
    @State private var capsuleDeduct = false
    @State private var showPointConfirmation = false
    @State private var pendingImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                cameraLayer

//                #if DEBUG
//                // App Store screenshot overlay
//                GeometryReader { geo in
//                    Image("fake_room")
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: geo.size.width, height: geo.size.height)
//                        .clipped()
//                }
//                .ignoresSafeArea()
//                .allowsHitTesting(false)
//                #endif

                controlsOverlay

                // Bottom neon glow
                BottomNeonGlow()
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .all)
            .containerBackground(.clear, for: .navigation)
            .background {
                ClearNavigationControllerBackground()
                ClearTabBarBackground()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    statusCapsule
                        .scaleEffect(capsuleScale)
                        .offset(x: capsuleShake)
                        .foregroundStyle(capsuleGold ? Color.aiPeach : .white)
                        .colorMultiply(capsuleDeduct ? Color(red: 1.0, green: 0.6, blue: 0.3) : capsuleGold ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white)
                        .animation(.easeInOut(duration: 0.6), value: capsuleGold)
                        .animation(.easeInOut(duration: 0.3), value: capsuleDeduct)
                        .onTapGesture {
                            playCapsuleAnimation()
                            
                            if subscriptionService.isPremium {
                                let vm = AppFactory.shared.makePaywallViewModel(initialTab: .subscription)
                                if let activeID = subscriptionService.activeProductID {
                                    vm.selectedProductID = activeID
                                }
                                paywallViewModel = vm
                            } else {
                                paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .points)
                            }
                        }
                        .onChange(of: subscriptionService.isPremium) { old, new in
                            guard !old, new else { return }
                            playCapsuleAnimation()
                        }
                        .onChange(of: subscriptionService.pointsBalance) { old, new in
                            if new > old {
                                playCapsuleAnimation()
                            } else if new < old {
                                playDeductAnimation()
                            }
                        }
                }
                
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
                    AppFactory.shared.analyticsService.track(.scanLimitReached(remainingPoints: subscriptionService.pointsBalance))
                    paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .subscription)
                    AppFactory.shared.analyticsService.track(.scanLimitPaywallShown())
                    return
                }

                if subscriptionService.willCostPoint {
                    pendingImage = image
                    showPointConfirmation = true
                } else {
                    capturedPhoto = CapturedPhoto(image: image)
                }
            }
            .onChange(of: viewModel.availableLenses) { _, lenses in
                cameraAccessory.availableLenses = lenses
            }
            .onChange(of: viewModel.activeLensIndex) { _, index in
                cameraAccessory.activeLensIndex = index
            }
            .sheet(item: $paywallViewModel) { vm in
                PaywallView(
                    viewModel: vm,
                    backgroundImage: nil,
                    score: nil
                )
                .presentationDetents([.large])
            }
            .onAppear {
                showCTA = false
                ctaHideTask?.cancel()
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    showCTA = true
                }
                ctaHideTask = Task {
                    try? await Task.sleep(for: .seconds(4))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.8)) {
                        showCTA = false
                    }
                }
            }
            .onDisappear {
                ctaHideTask?.cancel()
                showCTA = false
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
            .alert(
                String(localized: "confirm_use_point_title"),
                isPresented: $showPointConfirmation
            ) {
                Button(String(localized: "confirm_use_point_action")) {
                    if let image = pendingImage {
                        capturedPhoto = CapturedPhoto(image: image)
                    }
                    pendingImage = nil
                }
                Button(String(localized: "confirm_use_point_cancel"), role: .cancel) {
                    pendingImage = nil
                }
            } message: {
                Text(String(localized: "confirm_use_point_scan_message \(subscriptionService.pointsBalance)"))
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
            GradientBackground()
                .overlay { deniedView }
        case .notDetermined:
            GradientBackground()
                .containerRelativeFrame([.horizontal, .vertical])
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack {
            Spacer()

            // Provocative CTA wording
            VStack(spacing: 8) {
                Text(String(localized: "scan_cta_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .neonGlow(colors: [Color.rsAccent, .purple, .cyan], radius: 10, opacity: 0.4, duration: 30)

                Text(String(localized: "scan_cta_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
            .opacity(showCTA ? 1 : 0)
            .scaleEffect(showCTA ? 1 : 0.85)
            .animation(.spring(duration: 0.3, bounce: 0.3), value: showCTA)

            Spacer()
        }
    }

    private func playCapsuleAnimation() {
        Task {
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                capsuleScale = 1.25
            }
            capsuleGold = true
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                capsuleScale = 1.0
            }
            withAnimation(.easeInOut(duration: 0.8)) {
                capsuleGold = false
            }
        }
    }

    private func playDeductAnimation() {
        Task {
            capsuleDeduct = true
            // Shake sequence
            for offset: CGFloat in [8, -6, 4, -2, 0] {
                withAnimation(.easeInOut(duration: 0.08)) {
                    capsuleShake = offset
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
            try? await Task.sleep(for: .seconds(0.4))
            capsuleDeduct = false
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

    // MARK: - Status Capsule

    @ViewBuilder
    private var statusCapsule: some View {
        if subscriptionService.isPremium {
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                Text(String(localized: "scan_status_premium"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .neonGlow(colors: [.aiPurple, .aiPink, .aiLightBlue], radius: 10, opacity: 0.6, duration: 30)
        } else {
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "viewfinder")
                        .font(.caption)
                    Text(String(localized: "scan_remaining \(subscriptionService.remainingScansToday)"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                if subscriptionService.pointsBalance > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(String(localized: "scan_points_balance \(subscriptionService.pointsBalance)"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.aiPurple)
                }
            }
            .foregroundStyle(.white)
            .neonGlow(colors: [.aiDeepPurple, .aiPurple, .aiLightBlue], radius: 10, opacity: 0.5, duration: 30)
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
    let scan: RoomScan?

    static func == (lhs: ScanResultRoute, rhs: ScanResultRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Scan Flow (fullScreenCover: Analysis → Result)

private struct ScanFlowView: View {
    let image: UIImage
    let subscriptionService: SubscriptionServiceProtocol
    var onDismiss: () -> Void
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            AnalysisView(
                viewModel: AppFactory.shared.makeAnalysisViewModel(image: image),
                onResult: { result, img, scan in
                    _ = subscriptionService.recordScanWithSource()
                    path.append(ScanResultRoute(result: result, image: img, scan: scan))
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
                    scan: route.scan,
                    onDismiss: onDismiss
                )
            }
        }
    }
}

// MARK: - Bottom Neon Glow

private struct BottomNeonGlow: View {
    @State private var rotation: CGFloat = 0
    @State private var drift: CGFloat = 0

    private let glowColors: [Color] = [
        .purple, Color.rsAccent, .cyan, .pink, .purple
    ]

    var body: some View {
        VStack {
            Spacer()

            ZStack {
                // Rotating angular gradient — main glow
                Ellipse()
                    .fill(
                        AngularGradient(
                            colors: glowColors,
                            center: .center,
                            startAngle: .degrees(Double(rotation) * 360),
                            endAngle: .degrees(Double(rotation) * 360 + 360)
                        )
                    )
                    .frame(width: 500, height: 220)
                    .blur(radius: 50)
                    .opacity(0.35)

                // Secondary blob — drifts horizontally
                Ellipse()
                    .fill(
                        AngularGradient(
                            colors: [.cyan, .purple, Color.rsAccent, .pink, .cyan],
                            center: .center,
                            startAngle: .degrees(Double(-rotation) * 360 + 60),
                            endAngle: .degrees(Double(-rotation) * 360 + 420)
                        )
                    )
                    .frame(width: 300, height: 160)
                    .offset(x: 60 * sin(drift * .pi * 2))
                    .blur(radius: 40)
                    .opacity(0.3)

                // Tight bright core
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.rsAccent.opacity(0.6), .purple.opacity(0.4), .cyan.opacity(0.5)],
                            startPoint: UnitPoint(x: drift, y: 0),
                            endPoint: UnitPoint(x: 1 - drift, y: 1)
                        )
                    )
                    .frame(width: 200, height: 100)
                    .blur(radius: 25)
                    .opacity(0.4)
            }
            .frame(height: 200)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 1
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                drift = 1
            }
        }
    }
}

#Preview {
    ScanView(viewModel: ScanViewModel(), subscriptionService: SubscriptionService(), cameraAccessory: CameraAccessoryState())
}
