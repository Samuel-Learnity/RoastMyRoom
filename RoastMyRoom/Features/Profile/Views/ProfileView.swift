import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProfileViewModel?
    @State private var showPaywall = false
    @State private var paywallInitialTab: PaywallViewModel.PaywallTab = .points
    var onShowPaywall: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                Group {
                    if let vm = viewModel {
                        profileContent(vm: vm)
                    }
                }
            }
            .navigationTitle(String(localized: "profile_title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if viewModel == nil {
                    viewModel = AppFactory.shared.makeProfileViewModel(modelContext: modelContext)
                }
                viewModel?.loadStats()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    viewModel: AppFactory.shared.makePaywallViewModel(initialTab: paywallInitialTab),
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
                        paywallInitialTab = .points
                        showPaywall = true
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
                            paywallInitialTab = .subscription
                            showPaywall = true
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

                // Share
                glassSection(title: String(localized: "profile_section_about")) {
                    ShareLink(
                        item: URL(string: "https://apps.apple.com/app/roomscore")!,
                        subject: Text("RoastMyRoom"),
                        message: Text(String(localized: "profile_share_message"))
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white.opacity(0.7))
                            Text(String(localized: "profile_share_app"))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }

            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
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
