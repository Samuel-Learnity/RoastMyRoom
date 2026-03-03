import SwiftUI
import AVFoundation
import StoreKit

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var isRestoring = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                onboardingSlide(
                    image: "camera.viewfinder",
                    title: String(localized: "onboarding_title_1"),
                    subtitle: String(localized: "onboarding_subtitle_1")
                )
                .tag(0)

                onboardingSlide(
                    image: "star.circle",
                    title: String(localized: "onboarding_title_2"),
                    subtitle: String(localized: "onboarding_subtitle_2")
                )
                .tag(1)

                onboardingSlide(
                    image: "square.and.arrow.up",
                    title: String(localized: "onboarding_title_3"),
                    subtitle: String(localized: "onboarding_subtitle_3")
                )
                .overlay(alignment: .bottom) {
                    VStack(spacing: 12) {
                        ctaButton

                        Button {
                            Task {
                                isRestoring = true
                                try? await AppStore.sync()
                                isRestoring = false
                            }
                        } label: {
                            if isRestoring {
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                            } else {
                                Text(String(localized: "paywall_restore"))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        .disabled(isRestoring)
                    }
                    .padding(.bottom, 80)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            skipButton
        }
        .gradientBackground()
    }

    // MARK: - Subviews

    private func onboardingSlide(image: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var ctaButton: some View {
        Button {
            requestCameraAndFinish()
        } label: {
            Text(String(localized: "onboarding_cta"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.rsAccent, in: RoundedRectangle(cornerRadius: 16))
                .neonGlow(radius: 20, opacity: 0.6)
        }
        .padding(.horizontal, 32)
    }

    private var skipButton: some View {
        Button {
            requestCameraAndFinish()
        } label: {
            Text(String(localized: "onboarding_skip"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
    }

    // MARK: - Actions

    private func requestCameraAndFinish() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                AppFactory.shared.analyticsService.track(.cameraPermissionResult(granted: granted))
                AppFactory.shared.analyticsService.track(.onboardingCompleted())
                // Write to both Keychain (survives reinstall) and AppStorage (SwiftUI binding)
                AppFactory.shared.keychainService.set(true, forKey: "hasSeenOnboarding")
                hasSeenOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
