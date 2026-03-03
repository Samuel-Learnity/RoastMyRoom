import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ResultViewModel
    let subscriptionService: SubscriptionServiceProtocol
    var scan: RoomScan?
    var onDismiss: (() -> Void)?
    @State private var paywallViewModel: PaywallViewModel?
    @State private var showUnlockPointConfirmation = false

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
            .safeAreaInset(edge: .bottom) {
                if !viewModel.isPremium {
                    stickyBlurWall
                }
            }
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
        .sheet(item: $paywallViewModel) { vm in
            PaywallView(
                viewModel: vm,
                backgroundImage: viewModel.image,
                score: viewModel.scanResult.overallScore
            )
            .presentationDetents([.large])
        }
        .alert(
            String(localized: "confirm_use_point_title"),
            isPresented: $showUnlockPointConfirmation
        ) {
            Button(String(localized: "confirm_use_point_action")) {
                viewModel.unlockWithPoint(subscriptionService: subscriptionService, scan: scan)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button(String(localized: "confirm_use_point_cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "confirm_use_point_unlock_message \(subscriptionService.pointsBalance)"))
        }
        .onAppear { viewModel.trackResultViewed() }
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

            // Score + style overlaid at bottom
            VStack(spacing: 12) {
                ScoreCounterView(score: viewModel.scanResult.overallScore, verdict: viewModel.scanResult.verdict, animated: viewModel.animateEntrance)
                heroScoreBadge
            }
            .padding(.bottom, 32)
        }
        .frame(height: 500)
        .clipped()
        .background(alignment: .top) {
            Color.rsBgBase
                .ignoresSafeArea(edges: .top)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Content Sections

    private var contentSections: some View {
        LazyVStack(spacing: 0) {
            // Roast — primary content
            RoastBannerView(roast: viewModel.scanResult.roast)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            // Personality
            personalitySection
                .padding(.top, 32)

            // Mood board
            moodBoardSection
                .padding(.top, 32)

            // Radar chart with header
            radarSection
                .padding(.top, 32)

            // Sub-score comments
            subScoreCommentsSection
                .padding(.top, 8)

            // Tips
            tipsSection
                .padding(.top, 32)

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Radar

    @ViewBuilder
    private var radarSection: some View {
        if let subScores = viewModel.scanResult.subScores as SubScores? {
            VStack(spacing: 12) {
                sectionHeader(
                    title: String(localized: "result_breakdown_title"),
                    icon: "chart.dots.scatter"
                )
                RadarChartView(subScores: subScores, animated: viewModel.animateEntrance)
                    .frame(maxWidth: .infinity)
                    .redacted(reason: viewModel.isPremium ? [] : .placeholder)
            }
        }
    }

    // MARK: - Sub-Score Comments

    @ViewBuilder
    private var subScoreCommentsSection: some View {
        if let comments = viewModel.scanResult.subScoreComments,
           let subScores = viewModel.scanResult.subScores as SubScores? {
            SubScoreDetailView(
                subScores: subScores,
                comments: comments,
                isBlurred: !viewModel.isPremium
            )
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(spacing: 12) {
            sectionHeader(
                title: String(localized: "result_tips_title"),
                icon: "lightbulb.fill"
            )

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

    // MARK: - Personality

    @ViewBuilder
    private var personalitySection: some View {
        if let personality = viewModel.scanResult.personality {
            VStack(spacing: 12) {
                sectionHeader(
                    title: String(localized: "result_personality_title"),
                    icon: "person.crop.circle.badge.questionmark"
                )

                PersonalityCardView(
                    personality: personality,
                    isBlurred: !viewModel.isPremium
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Mood Board

    @ViewBuilder
    private var moodBoardSection: some View {
        if let moodBoard = viewModel.scanResult.moodBoard {
            VStack(spacing: 12) {
                sectionHeader(
                    title: String(localized: "result_moodboard_title"),
                    icon: "swatchpalette.fill"
                )

                MoodBoardView(
                    moodBoard: moodBoard,
                    isBlurred: !viewModel.isPremium
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Hero Score Badge

    @State private var showScorePill = false
    @State private var showStylePill = false

    private var heroScoreBadge: some View {
        HStack(spacing: 8) {
            // Score pill
            HStack(spacing: 6) {
                Text(String(format: "%.1f", viewModel.scanResult.overallScore))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("/10")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .neonGlow(colors: scoreGlowColors, radius: 8, opacity: 0.5)
            .scaleEffect(showScorePill ? 1 : 0.5)
            .opacity(showScorePill ? 1 : 0)

            // Style pill
            StyleBadgeView(styleName: viewModel.scanResult.style)
                .scaleEffect(showStylePill ? 1 : 0.5)
                .opacity(showStylePill ? 1 : 0)
        }
        .onAppear {
            guard viewModel.animateEntrance else {
                showScorePill = true
                showStylePill = true
                return
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(0.6)) {
                showScorePill = true
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.3).delay(1.0)) {
                showStylePill = true
            }
        }
    }

    private var scoreGlowColors: [Color] {
        switch viewModel.scanResult.overallScore {
        case 0..<4: [Color.aiCoral, Color.aiPeach, Color.aiPink]
        case 4..<6: [Color.aiPeach, Color.aiCoral, Color.aiLavender]
        case 6..<8: [Color.aiLightBlue, Color.aiPurple, Color.aiLavender]
        default:    [Color.aiPurple, Color.aiPink, Color.aiLightBlue]
        }
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

    // MARK: - Sticky Blur Wall

    private var stickyBlurWall: some View {
        VStack(spacing: 8) {
            // Primary: open paywall (subscription)
            Button {
                paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .subscription)
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
                    showUnlockPointConfirmation = true
                } else {
                    paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .points)
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
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 4)
        .background {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.3), location: 0.5),
                    .init(color: .black.opacity(0.5), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
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
