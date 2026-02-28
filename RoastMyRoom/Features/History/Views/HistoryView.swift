import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @Namespace private var heroNamespace
    let isPremium: Bool
    let subscriptionService: SubscriptionService
    var onShowPaywall: (() -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                Group {
                    if let vm = viewModel {
                        if vm.isEmpty {
                            emptyState
                        } else {
                            scrollContent(vm: vm)
                        }
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle(String(localized: "history_title"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: RoomScan.self) { scan in
                ResultView(
                    viewModel: AppFactory.shared.makeResultViewModel(
                        scanResult: ScanResult(from: scan),
                        image: UIImage(data: scan.imageData) ?? UIImage(),
                        isPremium: isPremium || scan.isPremiumResult,
                        animateEntrance: false
                    ),
                    subscriptionService: subscriptionService,
                    scan: scan
                )
                .navigationTransition(.zoom(sourceID: scan.id, in: heroNamespace))
            }
            .task {
                if viewModel == nil {
                    viewModel = AppFactory.shared.makeHistoryViewModel(modelContext: modelContext)
                }
                viewModel?.loadScans()
            }
            .alert(
                String(localized: "history_delete_title"),
                isPresented: Binding(
                    get: { viewModel?.showDeleteConfirmation ?? false },
                    set: { viewModel?.showDeleteConfirmation = $0 }
                )
            ) {
                Button(String(localized: "history_delete_confirm"), role: .destructive) {
                    viewModel?.deleteConfirmed()
                }
                Button(String(localized: "history_delete_cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "history_delete_message"))
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))

            Text(String(localized: "history_empty_title"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(String(localized: "history_empty_subtitle"))
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Scroll Content

    private func scrollContent(vm: HistoryViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if !vm.thisWeekScans.isEmpty {
                    sectionView(
                        title: String(localized: "history_section_this_week"),
                        scans: vm.thisWeekScans,
                        startIndex: 0,
                        vm: vm
                    )
                }

                if !vm.olderScans.isEmpty {
                    sectionView(
                        title: String(localized: "history_section_older"),
                        scans: vm.olderScans,
                        startIndex: vm.thisWeekScans.count,
                        vm: vm
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Skeleton

    private var skeletonGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Fake section header
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 16)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in
                        HistorySkeletonCard()
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Section

    private func sectionView(title: String, scans: [RoomScan], startIndex: Int, vm: HistoryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(scans.enumerated()), id: \.element.id) { index, scan in
                    let globalIndex = startIndex + index
                    let isLocked = !isPremium && globalIndex >= 3

                    if isLocked {
                        HistoryCardView(scan: scan, isLocked: true)
                            .onTapGesture { onShowPaywall?() }
                    } else {
                        NavigationLink(value: scan) {
                            HistoryCardView(scan: scan, isLocked: false)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: scan.id, in: heroNamespace)
                        .contextMenu {
                            Button(role: .destructive) {
                                vm.confirmDelete(scan)
                            } label: {
                                Label(String(localized: "history_delete_action"), systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Skeleton Card

private struct HistorySkeletonCard: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .aspectRatio(4/3, contentMode: .fill)

            // Fake score badge
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.12))
                .frame(width: 44, height: 28)
                .padding(12)
        }
        .shimmer(isActive: true)
    }
}

#Preview {
    HistoryView(isPremium: false, subscriptionService: SubscriptionService())
        .modelContainer(for: RoomScan.self, inMemory: true)
}
