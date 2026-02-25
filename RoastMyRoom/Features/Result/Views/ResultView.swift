import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: ResultViewModel
    var onDismiss: (() -> Void)?
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSections
            }
        }
        .scrollIndicators(.hidden)
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
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let shareImage = viewModel.shareImage {
                ShareSheet(items: [shareImage, viewModel.shareText])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                viewModel: AppFactory.shared.makePaywallViewModel(),
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

            // Gradient fade to content at bottom
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.4),
                    .init(color: .black.opacity(0.9), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Score + badge overlaid at bottom
            VStack(spacing: 16) {
                ScoreCounterView(score: viewModel.scanResult.overallScore)
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
        .background(Color(.systemBackground))
    }

    // MARK: - Roast

    private var roastSection: some View {
        RoastBannerView(roast: viewModel.scanResult.roast)
            .padding(.horizontal, 16)
    }

    // MARK: - Premium Content

    private var premiumContent: some View {
        VStack(spacing: 20) {
            if !viewModel.isPremium {
                blurWall
            }

            // Section header
            sectionHeader(
                title: String(localized: "result_breakdown_title"),
                icon: "chart.dots.scatter"
            )

            // Radar chart
            if let subScores = viewModel.scanResult.subScores as SubScores? {
                RadarChartView(subScores: subScores)
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
                        isBlurred: !viewModel.isPremium && index > 0
                    )
                }
            }
            .padding(.horizontal, 16)
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
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Blur Wall

    private var blurWall: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.subheadline)

                Text(String(localized: "result_unlock"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.rsAccent)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.rsAccent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.rsAccent.opacity(0.2), lineWidth: 1)
            )
            .neonGlow(colors: [Color.rsAccent, .purple, .pink], radius: 14, opacity: 0.4)
            .padding(.horizontal, 16)
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
            onDismiss: { }
        )
    }
}
