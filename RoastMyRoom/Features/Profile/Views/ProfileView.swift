import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProfileViewModel?
    @State private var showPaywall = false
    var onShowPaywall: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    profileList(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(String(localized: "profile_title"))
            .task {
                if viewModel == nil {
                    viewModel = AppFactory.shared.makeProfileViewModel(modelContext: modelContext)
                }
                viewModel?.loadStats()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    viewModel: AppFactory.shared.makePaywallViewModel(),
                    backgroundImage: nil,
                    score: nil
                )
                .presentationDetents([.large])
            }
        }
    }

    private func profileList(vm: ProfileViewModel) -> some View {
        List {
            // Stats
            Section(String(localized: "profile_section_stats")) {
                Label(String(localized: "profile_total_scans"), systemImage: "camera")
                    .badge("\(vm.totalScans)")
                Label(String(localized: "profile_average_score"), systemImage: "star")
                    .badge(vm.totalScans > 0 ? String(format: "%.1f", vm.averageScore) : "—")
                Label(String(localized: "profile_dominant_style"), systemImage: "paintpalette")
                    .badge(vm.dominantStyle)
            }

            // Subscription
            Section(String(localized: "profile_section_subscription")) {
                Label(vm.planLabel, systemImage: vm.planIcon)
                if !vm.isPremium {
                    Button(String(localized: "profile_upgrade")) {
                        showPaywall = true
                    }
                    .foregroundStyle(Color.rsAccent)
                }

                #if DEBUG
                Button {
                    vm.subscriptionService.debugTogglePremium()
                } label: {
                    Label(
                        vm.isPremium ? "DEBUG: Disable Premium" : "DEBUG: Enable Premium",
                        systemImage: vm.isPremium ? "lock.fill" : "lock.open.fill"
                    )
                }
                .foregroundStyle(vm.isPremium ? .red : .green)
                #endif
            }

            // Settings
            Section(String(localized: "profile_section_settings")) {
                Picker(String(localized: "profile_appearance"), selection: Binding(
                    get: { vm.preferredAppearance },
                    set: { vm.preferredAppearance = $0 }
                )) {
                    Text(String(localized: "profile_appearance_system")).tag("system")
                    Text(String(localized: "profile_appearance_light")).tag("light")
                    Text(String(localized: "profile_appearance_dark")).tag("dark")
                }
            }

            // Share
            Section(String(localized: "profile_section_about")) {
                ShareLink(
                    item: URL(string: "https://apps.apple.com/app/roomscore")!,
                    subject: Text("RoastMyRoom"),
                    message: Text(String(localized: "profile_share_message"))
                ) {
                    Label(String(localized: "profile_share_app"), systemImage: "square.and.arrow.up")
                }
            }

            // Footer
            Section {
                Text(String(localized: "profile_footer"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: RoomScan.self, inMemory: true)
}
