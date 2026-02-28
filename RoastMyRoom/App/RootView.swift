import SwiftUI
import PhotosUI

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

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showScanLimitPaywall = false
    @State private var cameraAccessory = CameraAccessoryState()
    @State private var scanViewModel = ScanViewModel()
    private let subscriptionService = AppFactory.shared.subscriptionService

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "scan_tab"), systemImage: "camera.viewfinder", value: 0) {
                ScanView(
                    viewModel: scanViewModel,
                    subscriptionService: subscriptionService,
                    cameraAccessory: cameraAccessory
                )
            }

            Tab(String(localized: "history_tab"), systemImage: "clock.arrow.circlepath", value: 1) {
                HistoryView(
                    isPremium: subscriptionService.isPremium,
                    subscriptionService: subscriptionService,
                    onShowPaywall: { showScanLimitPaywall = true }
                )
            }

            Tab(String(localized: "profile_tab"), systemImage: "person.crop.circle", value: 2) {
                ProfileView()
            }
        }
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
                    .foregroundStyle(.white) // TODO: attention quand on est en light theme -> non visible blanc sur blanc. Corrige et supprime le todo quand tu le liras
                    .frame(width: 44, height: 44)
            }
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
                        .stroke(.white, lineWidth: 2.5) // TODO: attention quand on est en light theme -> non visible blanc sur blanc. Corrige et supprime le todo quand tu le liras
                        .frame(width: 38, height: 38)
                    Circle()
                        .fill(.white) // TODO: attention quand on est en light theme -> non visible blanc sur blanc. Corrige et supprime le todo quand tu le liras
                        .frame(width: 32, height: 32)
                }
            }
            
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
