import SwiftUI

private let termsURL = URL(string: "https://web-neon-six-28.vercel.app/terms")!
private let privacyURL = URL(string: "https://web-neon-six-28.vercel.app/privacy")!
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State var viewModel: PaywallViewModel
    let backgroundImage: UIImage?
    let score: Float?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background: blurred room photo
                backgroundLayer

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)

                        headerSection
                        bulletsSection
                        plansSection

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 10) {
                        ctaButton
                        finePrint
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8), .black.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadProducts()
            }
            .onAppear {
                AppFactory.shared.analyticsService.track(.screenView(screenName: "paywall"))
            }
            .onDisappear {
                viewModel.trackPaywallClosed()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showAuthPrompt },
                set: { if !$0 { viewModel.dismissAuthPrompt() } }
            )) {
                authPromptSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Auth Prompt

    private var authPromptSheet: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(Color.rsAccent)

            Text(String(localized: "auth_prompt_title"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(String(localized: "auth_prompt_subtitle"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button {
                Task { await viewModel.signInFromPrompt() }
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.title3)
                    Text(String(localized: "auth_prompt_sign_in"))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.rsAccent, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Button {
                viewModel.dismissAuthPrompt()
                dismiss()
            } label: {
                Text(String(localized: "auth_prompt_later"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
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

                Text("/10")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(viewModel.selectedTab == .points
                ? String(localized: "paywall_title_points")
                : String(localized: "paywall_title_subscription"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: viewModel.selectedTab)
        }
    }

    // MARK: - Bullets

    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            bulletRow(String(localized: "paywall_bullet_unlimited_scans"))
            bulletRow(String(localized: "paywall_bullet_radar"))
            bulletRow(String(localized: "paywall_bullet_tips"))
            bulletRow(String(localized: "paywall_bullet_history"))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aiGlow(colors: [.purple.opacity(0.6), Color.rsAccent.opacity(0.5), .cyan.opacity(0.4)], cornerRadius: 20, glowRadius: 8, glowOpacity: 0.3)
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
                    viewModel.trackTabSwitch()
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
                spacing: 20
            ) {
                if viewModel.pointsProducts.isEmpty {
                    // Skeleton placeholders matching PointsPackCardView layout
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 32)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 40, height: 14)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.rsCardStroke, lineWidth: 1)
                        )
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
                // Skeleton placeholders matching PlanCardView layout
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 16)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 24)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 70, height: 12)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.rsCardStroke, lineWidth: 1)
                    )
                    .shimmer(isActive: true)
                }
            } else {
                if let weekly = viewModel.weeklyProduct {
                    PlanCardView(
                        product: weekly,
                        isSelected: viewModel.selectedProductID == weekly.id,
                        isBestValue: false,
                        isActive: viewModel.activeProductID == weekly.id
                    )
                    .onTapGesture { viewModel.selectedProductID = weekly.id }
                }

                if let annual = viewModel.annualProduct {
                    PlanCardView(
                        product: annual,
                        isSelected: viewModel.selectedProductID == annual.id,
                        isBestValue: viewModel.activeProductID != annual.id,
                        isActive: viewModel.activeProductID == annual.id
                    )
                    .onTapGesture { viewModel.selectedProductID = annual.id }
                }

                if let lifetime = viewModel.lifetimeProduct {
                    PlanCardView(
                        product: lifetime,
                        isSelected: viewModel.selectedProductID == lifetime.id,
                        isBestValue: false,
                        isActive: viewModel.activeProductID == lifetime.id
                    )
                    .onTapGesture { viewModel.selectedProductID = lifetime.id }
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            viewModel.trackCtaClicked()
            Task {
                let success = await viewModel.purchase()
                if success && !viewModel.showAuthPrompt { dismiss() }
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
                Button(String(localized: "paywall_terms")) { openURL(termsURL) }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))

                Button(String(localized: "paywall_privacy")) { openURL(privacyURL) }
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

}

#Preview {
    PaywallView(
        viewModel: PaywallViewModel(subscriptionService: SubscriptionService()),
        backgroundImage: nil,
        score: 7.3
    )
}
