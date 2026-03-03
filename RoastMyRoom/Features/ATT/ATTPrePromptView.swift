import SwiftUI
import AppTrackingTransparency

struct ATTPrePromptView: View {
    @AppStorage("hasRespondedToATT") private var hasRespondedToATT = false
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    private let analyticsService = AppFactory.shared.analyticsService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            icon
            titleSection
            bulletsSection

            Spacer()

            buttonsSection
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
        .gradientBackground()
        .onAppear {
            analyticsService.track(.attPrePromptShown())
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                iconScale = 1
                iconOpacity = 1
            }
        }
    }

    // MARK: - Subviews

    private var icon: some View {
        Image(systemName: "hand.raised.circle.fill")
            .font(.system(size: 80))
            .foregroundStyle(.white)
            .symbolEffect(.pulse, options: .repeating)
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
    }

    private var titleSection: some View {
        Text(String(localized: "att_title"))
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            bulletRow(icon: "chart.bar.fill", text: String(localized: "att_bullet_1"))
            bulletRow(icon: "hand.thumbsup.fill", text: String(localized: "att_bullet_2"))
            bulletRow(icon: "lock.shield.fill", text: String(localized: "att_bullet_3"))
        }
        .padding(.horizontal, 8)
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 28)

            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button {
                continueAction()
            } label: {
                Text(String(localized: "att_continue"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.rsAccent, in: RoundedRectangle(cornerRadius: 16))
                    .neonGlow(radius: 20, opacity: 0.6)
            }

            Button {
                skipAction()
            } label: {
                Text(String(localized: "att_skip"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Actions

    private func continueAction() {
        analyticsService.track(.attPrePromptContinue())
        Task {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            let statusString = statusName(status)
            analyticsService.track(.attPermissionResult(status: statusString))
            analyticsService.setUserProperty(statusString, forName: "att_status")
            hasRespondedToATT = true
        }
    }

    private func skipAction() {
        let statusString = statusName(ATTrackingManager.trackingAuthorizationStatus)
        analyticsService.track(.attPermissionResult(status: statusString))
        analyticsService.setUserProperty(statusString, forName: "att_status")
        hasRespondedToATT = true
    }

    private func statusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .authorized: "authorized"
        case .denied: "denied"
        case .restricted: "restricted"
        case .notDetermined: "not_determined"
        @unknown default: "unknown"
        }
    }
}

#Preview {
    ATTPrePromptView()
}
