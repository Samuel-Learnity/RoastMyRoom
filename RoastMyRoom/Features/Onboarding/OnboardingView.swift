import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

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
                    ctaButton
                        .padding(.bottom, 80)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            skipButton
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    private func onboardingSlide(image: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: image)
                .font(.system(size: 80))
                .foregroundStyle(Color.rsAccent)
                .symbolEffect(.pulse, options: .repeating)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
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
        }
        .padding(.horizontal, 32)
    }

    private var skipButton: some View {
        Button {
            hasSeenOnboarding = true
        } label: {
            Text(String(localized: "onboarding_skip"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Actions

    private func requestCameraAndFinish() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            Task { @MainActor in
                hasSeenOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView()
}
