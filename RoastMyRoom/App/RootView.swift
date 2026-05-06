import SwiftUI
import PhotosUI
import AppTrackingTransparency

// MARK: - Camera Accessory State

@MainActor
@Observable
final class CameraAccessoryState {
    var onCapture: (() -> Void)?
    var selectedPhotoItem: PhotosPickerItem?
    var onPickedImage: ((UIImage) -> Void)?

    // Lens
    var availableLenses: [ScanViewModel.Lens] = []
    var activeLensIndex: Int = 0
    var onSwitchLens: ((Int) -> Void)?
    var showLensPicker = false
    var lensHideTask: Task<Void, Never>?

    func scheduleLensHide() {
        lensHideTask?.cancel()
        lensHideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.3)) {
                showLensPicker = false
            }
        }
    }
}

// MARK: - Root

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasRespondedToATT") private var hasRespondedToATT = false
    @State private var launchReveal = false

    var body: some View {
        Group {
            if !hasRespondedToATT {
                ATTPrePromptView()
            } else if !hasSeenOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .overlay { launchBlurOverlay }
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeOut(duration: 0.6)) {
                launchReveal = true
            }
        }
    }

    private var launchBlurOverlay: some View {
        ZStack {
            Color.rsBgBase
            Color.rsAccent.opacity(0.15)
        }
        .ignoresSafeArea()
        .scaleEffect(launchReveal ? 30 : 1)
        .opacity(launchReveal ? 0 : 1)
        .allowsHitTesting(!launchReveal)
    }

    init() {
        let keychain = AppFactory.shared.keychainService

        // Auto-skip ATT pre-prompt for existing users who already responded to ATT
        // Must run BEFORE Keychain migration so we detect returning users correctly
        let keychainHasOnboarding = keychain.getBool(forKey: "hasSeenOnboarding") == true
        if keychainHasOnboarding,
           !UserDefaults.standard.bool(forKey: "hasRespondedToATT") {
            let attStatus = ATTrackingManager.trackingAuthorizationStatus
            if attStatus != .notDetermined {
                UserDefaults.standard.set(true, forKey: "hasRespondedToATT")
            }
        }

        // Migrate hasSeenOnboarding from Keychain → AppStorage if needed
        if keychainHasOnboarding,
           !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showScanLimitPaywall = false
    @State private var cameraAccessory = CameraAccessoryState()
    @State private var scanViewModel = AppFactory.shared.makeScanViewModel()
    @State private var historyViewModel: HistoryViewModel?
    @State private var profileViewModel: ProfileViewModel?
    private let subscriptionService = AppFactory.shared.subscriptionService

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "history_tab"), systemImage: "clock.arrow.circlepath", value: 1) {
                HistoryView(
                    viewModel: historyViewModel,
                    isPremium: subscriptionService.isPremium,
                    subscriptionService: subscriptionService,
                    onShowPaywall: { showScanLimitPaywall = true }
                )
            }

            Tab(String(localized: "scan_tab"), systemImage: "camera.viewfinder", value: 0) {
                ScanView(
                    viewModel: scanViewModel,
                    subscriptionService: subscriptionService,
                    cameraAccessory: cameraAccessory
                )
            }

            Tab(String(localized: "profile_tab"), systemImage: "person.crop.circle", value: 2) {
                ProfileView(viewModel: profileViewModel)
            }
        }
        .task {
            // Pre-render gradient background so tab switches are instant
            _ = await GradientBackgroundCache.shared.render()

            if historyViewModel == nil {
                let hvm = AppFactory.shared.makeHistoryViewModel(modelContext: modelContext)
                historyViewModel = hvm
                await hvm.loadScans()
            }
            if profileViewModel == nil {
                let pvm = AppFactory.shared.makeProfileViewModel(modelContext: modelContext)
                profileViewModel = pvm
                await pvm.loadStats()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            let tabNames: [Int: String] = [0: "scan", 1: "history", 2: "profile"]
            let tabName = tabNames[newTab] ?? "unknown"
            AppFactory.shared.analyticsService.track(.tabSwitched(tab: tabName))
        }
        .tabViewStyle(.tabBarOnly)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: selectedTab == 0) {
            CameraAccessoryBar(state: cameraAccessory)
        }
        .tint(.rsAccent)
        .sheet(isPresented: $showScanLimitPaywall) {
            PaywallView(
                viewModel: AppFactory.shared.makePaywallViewModel(),
                backgroundImage: nil,
                score: nil
            )
            .presentationSizing(.fitted)
        }
    }
}

// MARK: - Camera Accessory Bar

private struct CameraAccessoryBar: View {
    @Bindable var state: CameraAccessoryState

    var body: some View {
        
        HStack(alignment: .center, spacing: 32) {
            // Gallery
            PhotosPicker(
                selection: $state.selectedPhotoItem,
                matching: .images
            ) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(String(localized: "accessibility_photo_library"))
            .onChange(of: state.selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        state.onPickedImage?(image)
                    }
                }
            }
            
            // Shutter
            Button {
                state.onCapture?()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 2.5)
                        .frame(width: 38, height: 38)
                    Circle()
                        .fill(.white)
                        .frame(width: 32, height: 32)
                }
            }
            .accessibilityLabel(String(localized: "accessibility_take_photo"))
            
            if state.availableLenses.count > 1 {
                lensPicker
            }
        }
    }
    
    private var lensPicker: some View {
        HStack(spacing: 4) {
            if state.showLensPicker {
                ForEach(Array(state.availableLenses.enumerated()), id: \.element.id) { index, lens in
                    Button {
                        if index == state.activeLensIndex {
                            withAnimation(.spring(duration: 0.3)) {
                                state.showLensPicker = false
                            }
                        } else {
                            state.onSwitchLens?(index)
                            state.scheduleLensHide()
                        }
                    } label: {
                        Text(lens.label)
                            .font(.system(size: 13, weight: index == state.activeLensIndex ? .bold : .medium, design: .rounded))
                            .foregroundStyle(index == state.activeLensIndex ? .yellow : .white)
                            .frame(width: 40, height: 40)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            } else {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        state.showLensPicker = true
                    }
                    state.scheduleLensHide()
                } label: {
                    Text(state.availableLenses.indices.contains(state.activeLensIndex)
                         ? state.availableLenses[state.activeLensIndex].label
                         : "1×")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: state.showLensPicker)
        .animation(.spring(duration: 0.3), value: state.activeLensIndex)
    }
}


#Preview {
    RootView()
}
