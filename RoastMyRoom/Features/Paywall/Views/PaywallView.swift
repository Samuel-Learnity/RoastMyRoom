import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PaywallViewModel
    let backgroundImage: UIImage?
    let score: Float?

    var body: some View {
        ZStack {
            // Background: blurred room photo
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    headerSection
                    bulletsSection
                    socialProofSection
                    plansSection
                    ctaButton
                    finePrint
                    skipButton

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .task {
            await viewModel.loadProducts()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .blur(radius: 20)
            }
            Color.black.opacity(0.6)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            if let score {
                Text(String(format: "%.1f", score))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    .onAppear { pulseScale = 1.1 }

                Text("/10")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(String(localized: "paywall_title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }

    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Bullets

    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            bulletRow(String(localized: "paywall_bullet_subscores"))
            bulletRow(String(localized: "paywall_bullet_tips"))
            bulletRow(String(localized: "paywall_bullet_history"))
        }
        .padding(20)
        .glassBackground()
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.rsAccent)
            Text(text)
                .font(.body)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        Text(String(localized: "paywall_social_proof"))
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
    }

    // MARK: - Plans

    private var plansSection: some View {
        HStack(spacing: 12) {
            if let weekly = viewModel.weeklyProduct {
                PlanCardView(
                    product: weekly,
                    isSelected: viewModel.selectedProductID == weekly.id,
                    isBestValue: false
                )
                .onTapGesture { viewModel.selectedProductID = weekly.id }
            }

            if let annual = viewModel.annualProduct {
                PlanCardView(
                    product: annual,
                    isSelected: viewModel.selectedProductID == annual.id,
                    isBestValue: true
                )
                .onTapGesture { viewModel.selectedProductID = annual.id }
            }

            if let lifetime = viewModel.lifetimeProduct {
                PlanCardView(
                    product: lifetime,
                    isSelected: viewModel.selectedProductID == lifetime.id,
                    isBestValue: false
                )
                .onTapGesture { viewModel.selectedProductID = lifetime.id }
            }
        }
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task {
                let success = await viewModel.purchase()
                if success { dismiss() }
            }
        } label: {
            Group {
                if viewModel.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.ctaText)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.rsAccent, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .foregroundStyle(.white)
        }
        .neonGlow(colors: [.purple, Color.rsAccent, .pink], radius: 20, opacity: 0.6)
        .disabled(viewModel.isPurchasing || viewModel.selectedProduct == nil)

        // Error display
        .overlay(alignment: .bottom) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                    .offset(y: 24)
            }
        }
    }

    // MARK: - Fine Print

    private var finePrint: some View {
        VStack(spacing: 8) {
            Text(String(localized: "paywall_cancel_anytime"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 16) {
                Button(String(localized: "paywall_terms")) {}
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                Button(String(localized: "paywall_privacy")) {}
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                Button(String(localized: "paywall_restore")) {
                    Task { await viewModel.restore() }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Skip

    private var skipButton: some View {
        Button {
            dismiss()
        } label: {
            Text(String(localized: "paywall_skip"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

#Preview {
    PaywallView(
        viewModel: PaywallViewModel(subscriptionService: SubscriptionService()),
        backgroundImage: nil,
        score: 7.3
    )
}
