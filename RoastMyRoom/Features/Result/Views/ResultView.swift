import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ResultViewModel
    let subscriptionService: SubscriptionService
    var scan: RoomScan?
    var onDismiss: (() -> Void)?
    @State private var showPaywall = false
    @State private var paywallInitialTab: PaywallViewModel.PaywallTab = .points

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSections
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if let onDismiss { onDismiss() } else { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    if let onDismiss { onDismiss() } else { dismiss() }
                } label: {
                    Label(String(localized: "result_scan_again"), systemImage: "arrow.counterclockwise")
                }

                Button {
                    viewModel.generateShareCard()
                } label: {
                    Label(String(localized: "result_share"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let shareImage = viewModel.shareImage {
                ShareSheet(items: [shareImage, viewModel.shareText])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                viewModel: AppFactory.shared.makePaywallViewModel(initialTab: paywallInitialTab),
                backgroundImage: viewModel.image,
                score: viewModel.scanResult.overallScore
            )
            .presentationDetents([.large])
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Room photo
            Color.clear
                .background {
                    Image(uiImage: viewModel.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .clipped()

            // Gradient fade to gradient background
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.3),
                    .init(color: Color.rsBgBase, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Score + badge overlaid at bottom
            VStack(spacing: 16) {
                ScoreCounterView(score: viewModel.scanResult.overallScore, verdict: viewModel.scanResult.verdict, animated: viewModel.animateEntrance)
                StyleBadgeView(styleName: viewModel.scanResult.style)
            }
            .padding(.bottom, 32)
        }
        .frame(height: 500)
        .clipped()
        .background(alignment: .top) {
            // Blurred extension of the photo top into the safe area
            Image(uiImage: viewModel.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 80)
                .clipped()
                .blur(radius: 30)
                .scaleEffect(x: 1.2, y: 2.5, anchor: .top)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Content Sections

    private var contentSections: some View {
        VStack(spacing: 24) {
            roastSection
                .padding(.top, 24)

            premiumContent

            Spacer().frame(height: 24)
        }
        .background(Color.clear)
    }

    // MARK: - Roast

    private var roastSection: some View {
        RoastBannerView(roast: viewModel.scanResult.roast, animated: viewModel.animateEntrance)
            .padding(.horizontal, 16)
    }

    // MARK: - Premium Content

    private var premiumContent: some View {
        VStack(spacing: 20) {
            // Section header — always visible
            sectionHeader(
                title: String(localized: "result_breakdown_title"),
                icon: "chart.dots.scatter"
            )

            // Overall score summary — always visible (even free users)
            overallScoreSummary

            if !viewModel.isPremium {
                blurWall
            }

            // Radar chart
            if let subScores = viewModel.scanResult.subScores as SubScores? {
                RadarChartView(subScores: subScores, animated: viewModel.animateEntrance)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                    .blur(radius: viewModel.isPremium ? 0 : 8)
            }

            // Tips section header
            sectionHeader(
                title: String(localized: "result_tips_title"),
                icon: "lightbulb.fill"
            )

            // Tips
            VStack(spacing: 10) {
                ForEach(Array(viewModel.scanResult.tips.enumerated()), id: \.offset) { index, tip in
                    TipCardView(
                        tip: tip,
                        index: index,
                        isBlurred: !viewModel.isPremium && index > 0,
                        animated: viewModel.animateEntrance
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Overall Score Summary

    private var overallScoreSummary: some View {
        HStack(spacing: 12) {
            Text(String(format: "%.1f", viewModel.scanResult.overallScore))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color.scoreColor(for: viewModel.scanResult.overallScore))

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "result_overall_score"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text("/10")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassBackground()
        .padding(.horizontal, 16)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.rsAccent)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.7))

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Blur Wall

    private var blurWall: some View {
        VStack(spacing: 10) {
            // Primary: open paywall (subscription)
            Button {
                paywallInitialTab = .subscription
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)

                    Text(String(localized: "result_unlock"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .aiGlow(colors: [Color.rsAccent, .purple, .cyan, .pink], cornerRadius: 12, glowRadius: 10, glowOpacity: 0.7)
            }

            // Secondary: unlock with 1 point
            Button {
                if subscriptionService.hasPoints {
                    viewModel.unlockWithPoint(subscriptionService: subscriptionService, scan: scan)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else {
                    paywallInitialTab = .points
                    showPaywall = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .font(.subheadline)

                    if subscriptionService.hasPoints {
                        Text(String(localized: "result_unlock_point"))
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("(\(subscriptionService.pointsBalance) pts)")
                            .font(.caption)
                    } else {
                        Text(String(localized: "result_unlock_point_none"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - ShareSheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ResultView(
            viewModel: ResultViewModel(
                scanResult: .mock,
                image: UIImage(systemName: "photo.artframe")!
            ),
            subscriptionService: SubscriptionService(),
            onDismiss: { }
        )
    }
}
