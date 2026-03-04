import SwiftUI
import SwiftData

private let privacyURL = URL(string: "https://web-neon-six-28.vercel.app/privacy")!
private let termsURL = URL(string: "https://web-neon-six-28.vercel.app/terms")!
private let eulaURL = URL(string: "https://web-neon-six-28.vercel.app/eula")!
private let supportURL = URL(string: "https://web-neon-six-28.vercel.app/support")!

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @State var viewModel: ProfileViewModel?
    @State private var paywallViewModel: PaywallViewModel?
    var onShowPaywall: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                Group {
                    if let vm = viewModel, !vm.isLoading {
                        profileContent(vm: vm)
                    } else {
                        profileSkeleton
                    }
                }
            }
            .containerBackground(.clear, for: .navigation)
            .background(ClearNavigationControllerBackground())
            .navigationTitle(String(localized: "profile_title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel?.syncAuthState()
                viewModel?.refreshStats()
                AppFactory.shared.analyticsService.track(.screenView(screenName: "profile"))
            }
            .sheet(item: $paywallViewModel) { vm in
                PaywallView(
                    viewModel: vm,
                    backgroundImage: nil,
                    score: nil
                )
                .presentationDetents([.large])
            }
        }
    }

    private func profileContent(vm: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account
                accountSection(vm: vm)

                // Stats
                glassSection(title: String(localized: "profile_section_stats")) {
                    profileRow(icon: "camera", label: String(localized: "profile_total_scans"), value: "\(vm.totalScans)")
                    Divider().overlay(Color.white.opacity(0.1))
                    profileRow(icon: "star", label: String(localized: "profile_average_score"), value: vm.totalScans > 0 ? String(format: "%.1f", vm.averageScore) : "—")
                    Divider().overlay(Color.white.opacity(0.1))
                    profileRow(icon: "paintpalette", label: String(localized: "profile_dominant_style"), value: vm.dominantStyle)
                }

                // Points
                glassSection(title: String(localized: "profile_section_points")) {
                    profileRow(
                        icon: "star.circle.fill",
                        label: String(localized: "profile_points_balance"),
                        value: "\(vm.subscriptionService.pointsBalance)"
                    )
                    Divider().overlay(Color.white.opacity(0.1))
                    Button {
                        paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .points)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rsAccent)
                            Text(String(localized: "profile_buy_points"))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rsAccent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }

                // Subscription
                glassSection(title: String(localized: "profile_section_subscription")) {
                    profileRow(icon: vm.planIcon, label: vm.planLabel, value: nil)
                    if !vm.isPremium {
                        Divider().overlay(Color.white.opacity(0.1))
                        Button {
                            vm.trackUpgradeClicked()
                            paywallViewModel = AppFactory.shared.makePaywallViewModel(initialTab: .subscription)
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(Color.rsAccent)
                                Text(String(localized: "profile_upgrade"))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.rsAccent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }

                    #if DEBUG
                    Divider().overlay(Color.white.opacity(0.1))
                    Button {
                        vm.subscriptionService.debugTogglePremium()
                    } label: {
                        HStack {
                            Image(systemName: vm.isPremium ? "lock.fill" : "lock.open.fill")
                            Text(vm.isPremium ? "DEBUG: Disable Premium" : "DEBUG: Enable Premium")
                            Spacer()
                        }
                        .foregroundStyle(vm.isPremium ? .red : .green)
                    }
                    #endif
                }

                // About & Legal
                glassSection(title: String(localized: "profile_section_about")) {
                    ShareLink(
                        item: URL(string: "https://apps.apple.com/app/roomscore")!,
                        subject: Text("RoastMyRoom"),
                        message: Text(String(localized: "profile_share_message"))
                    ) {
                        profileLinkRow(icon: "square.and.arrow.up", label: String(localized: "profile_share_app"))
                    }
                    Divider().overlay(Color.white.opacity(0.1))
                    Button { openURL(privacyURL) } label: {
                        profileLinkRow(icon: "hand.raised", label: String(localized: "profile_privacy_policy"))
                    }
                    Divider().overlay(Color.white.opacity(0.1))
                    Button { openURL(termsURL) } label: {
                        profileLinkRow(icon: "doc.text", label: String(localized: "profile_terms_of_service"))
                    }
                    Divider().overlay(Color.white.opacity(0.1))
                    Button { openURL(eulaURL) } label: {
                        profileLinkRow(icon: "doc.plaintext", label: String(localized: "profile_eula"))
                    }
                    Divider().overlay(Color.white.opacity(0.1))
                    Button { openURL(supportURL) } label: {
                        profileLinkRow(icon: "questionmark.circle", label: String(localized: "profile_support"))
                    }
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Account Section

    private func accountSection(vm: ProfileViewModel) -> some View {
        glassSection(title: String(localized: "profile_section_account")) {
            if vm.isAuthenticated {
                profileRow(
                    icon: "person.crop.circle.fill",
                    label: vm.userDisplayName,
                    value: nil
                )

                if vm.signUpBonusGranted {
                    Divider().overlay(Color.white.opacity(0.1))
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(Color.rsAccent)
                        Text(String(localized: "profile_sign_up_bonus_granted"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rsAccent)
                    }
                }

                Divider().overlay(Color.white.opacity(0.1))
                Button {
                    vm.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red.opacity(0.8))
                        Text(String(localized: "profile_sign_out"))
                            .foregroundStyle(.red.opacity(0.8))
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text(String(localized: "profile_sign_in_description"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Sign-up bonus teaser (only if not yet claimed)
                    if vm.showSignUpBonusTeaser {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(Color.rsAccent)
                            Text(String(localized: "profile_sign_up_bonus"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rsAccent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await vm.signInWithApple() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text(String(localized: "profile_sign_in_apple"))
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if vm.isSigningIn {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.5))
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }
                    .disabled(vm.isSigningIn)

                    if let error = vm.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Glass Section

    private func glassSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.8)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .glassBackground()
        }
    }

    // MARK: - Skeleton

    private var profileSkeleton: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    skeletonSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private var skeletonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 12)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 24, height: 24)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 14)
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 14)
                    }
                }
            }
            .padding(16)
            .glassBackground()
        }
        .shimmer(isActive: true)
        .accessibilityHidden(true)
    }

    // MARK: - Profile Link Row

    private func profileLinkRow(icon: String, label: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    // MARK: - Profile Row

    private func profileRow(icon: String, label: String, value: String?) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            if let value {
                Text(value)
                    .foregroundStyle(.white.opacity(0.6))
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: RoomScan.self, inMemory: true)
}
