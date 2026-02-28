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
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 20)
                }
                .ignoresSafeArea()
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
            } else {
                GradientBackground()
            }
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

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 16) {
            tabPicker

            switch viewModel.selectedTab {
            case .points:
                pointsContent
            case .subscription:
                subscriptionContent
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(PaywallViewModel.PaywallTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    Text(tab == .points
                        ? String(localized: "paywall_tab_points")
                        : String(localized: "paywall_tab_unlimited"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.selectedTab == tab ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedTab == tab
                                ? Color.rsAccent.opacity(0.2)
                                : Color.clear,
                            in: Capsule()
                        )
                }
            }
        }
        .padding(4)
        .glassBackground(cornerRadius: 24)
    }

    // MARK: - Points Content

    private var pointsContent: some View {
        VStack(spacing: 12) {
            // Balance indicator
            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(Color.rsAccent)
                Text(String(localized: "paywall_balance \(viewModel.pointsBalance)"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            // 2×2 grid
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                if viewModel.pointsProducts.isEmpty {
                    // Skeleton placeholders
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                            .aspectRatio(1, contentMode: .fit)
                            .shimmer(isActive: true)
                    }
                } else {
                    ForEach(PointsPack.all) { pack in
                        if let product = viewModel.pointsProducts.first(where: { $0.id == pack.id }) {
                            PointsPackCardView(
                                product: product,
                                pack: pack,
                                isSelected: viewModel.selectedPointsPackID == pack.id
                            )
                            .onTapGesture { viewModel.selectedPointsPackID = pack.id }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subscription Content

    private var subscriptionContent: some View {
        HStack(spacing: 12) {
            if viewModel.products.isEmpty {
                // Skeleton placeholders
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.06))
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .shimmer(isActive: true)
                }
            } else {
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
            .foregroundStyle(.white)
        }
        .aiGlow(colors: [.purple, Color.rsAccent, .cyan, .pink], cornerRadius: 16, glowRadius: 14, glowOpacity: 0.8)
        .disabled(viewModel.isPurchasing || (viewModel.selectedTab == .subscription && viewModel.selectedProduct == nil) || (viewModel.selectedTab == .points && viewModel.selectedPointsProduct == nil))

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
            if viewModel.selectedTab == .points {
                Text(String(localized: "paywall_points_non_restorable"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                Text(String(localized: "paywall_cancel_anytime"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 16) {
                Button(String(localized: "paywall_terms")) {}
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                Button(String(localized: "paywall_privacy")) {}
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                if viewModel.selectedTab == .subscription {
                    Button(String(localized: "paywall_restore")) {
                        Task { await viewModel.restore() }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                }
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
