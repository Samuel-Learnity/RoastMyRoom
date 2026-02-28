import SwiftUI
import SwiftData

@MainActor
final class AppFactory {
    static let shared = AppFactory()

    // MARK: - Services

    private let imageProcessor: ImageProcessorProtocol = ImageProcessor()
    private let apiClient: APIClientProtocol
    let scoringService: ScoringServiceProtocol
    let storageService: StorageServiceProtocol
    let subscriptionService: SubscriptionService

    // Supabase anon (public) key — safe to embed in client apps
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4cXprbG12enpqY3p5amN5emRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5NTYyMTIsImV4cCI6MjA4NzUzMjIxMn0.WPas_XwdY4_WZqvWqtSFBU_Ye-8CKF3GAxzIzkL1wH8"

    private init() {
        self.apiClient = APIClient(
            baseURL: "https://rxqzklmvzzjczyjcyzdo.supabase.co/functions/v1",
            apiKey: Self.supabaseAnonKey
        )
        self.scoringService = ScoringService(apiClient: apiClient, imageProcessor: imageProcessor)
        self.storageService = StorageService()
        self.subscriptionService = SubscriptionService()
    }

    // MARK: - Model Container

    lazy var modelContainer: ModelContainer = {
        let schema = Schema([RoomScan.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - ViewModels

    func makeScanViewModel() -> ScanViewModel {
        ScanViewModel()
    }

    func makeAnalysisViewModel(image: UIImage) -> AnalysisViewModel {
        AnalysisViewModel(
            image: image,
            scoringService: scoringService,
            storageService: storageService
        )
    }

    func makeResultViewModel(scanResult: ScanResult, image: UIImage, isPremium: Bool, animateEntrance: Bool = true) -> ResultViewModel {
        ResultViewModel(scanResult: scanResult, image: image, isPremium: isPremium, animateEntrance: animateEntrance)
    }

    func makeHistoryViewModel(modelContext: ModelContext) -> HistoryViewModel {
        HistoryViewModel(
            storageService: storageService,
            modelContext: modelContext
        )
    }

    func makeProfileViewModel(modelContext: ModelContext) -> ProfileViewModel {
        ProfileViewModel(
            storageService: storageService,
            subscriptionService: subscriptionService,
            modelContext: modelContext
        )
    }

    func makePaywallViewModel(initialTab: PaywallViewModel.PaywallTab = .points) -> PaywallViewModel {
        PaywallViewModel(subscriptionService: subscriptionService, initialTab: initialTab)
    }
}
