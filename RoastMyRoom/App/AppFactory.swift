import SwiftUI
import SwiftData

@MainActor
final class AppFactory {
    static let shared = AppFactory()

    // MARK: - Services

    let keychainService: KeychainServiceProtocol = KeychainService()
    private let imageProcessor: ImageProcessorProtocol = ImageProcessor()
    private let apiClient: APIClientProtocol
    let scoringService: ScoringServiceProtocol
    let storageService: StorageServiceProtocol
    let subscriptionService: SubscriptionServiceProtocol
    let analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    let authService: AuthServiceProtocol

    // Supabase config
    private static let supabaseURL = "https://rxqzklmvzzjczyjcyzdo.supabase.co"
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4cXprbG12enpqY3p5amN5emRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5NTYyMTIsImV4cCI6MjA4NzUzMjIxMn0.WPas_XwdY4_WZqvWqtSFBU_Ye-8CKF3GAxzIzkL1wH8"

    private init() {
        let keychain = keychainService
        let auth = AuthService(
            keychainService: keychain,
            apiBaseURL: Self.supabaseURL,
            apiKey: Self.supabaseAnonKey
        )
        self.authService = auth
        self.apiClient = APIClient(
            baseURL: Self.supabaseURL + "/functions/v1",
            apiKey: Self.supabaseAnonKey
        )
        self.scoringService = ScoringService(apiClient: apiClient, imageProcessor: imageProcessor)
        self.storageService = StorageService()
        self.subscriptionService = SubscriptionService(
            keychainService: keychain,
            supabaseBaseURL: Self.supabaseURL,
            supabaseAnonKey: Self.supabaseAnonKey
        )
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
        ScanViewModel(analyticsService: analyticsService)
    }

    func makeAnalysisViewModel(image: UIImage) -> AnalysisViewModel {
        AnalysisViewModel(
            image: image,
            scoringService: scoringService,
            storageService: storageService,
            analyticsService: analyticsService
        )
    }

    func makeResultViewModel(scanResult: ScanResult, image: UIImage, isPremium: Bool, animateEntrance: Bool = true) -> ResultViewModel {
        ResultViewModel(scanResult: scanResult, image: image, isPremium: isPremium, animateEntrance: animateEntrance, analyticsService: analyticsService)
    }

    func makeHistoryViewModel(modelContext: ModelContext) -> HistoryViewModel {
        HistoryViewModel(
            storageService: storageService,
            modelContext: modelContext,
            analyticsService: analyticsService
        )
    }

    func makeProfileViewModel(modelContext: ModelContext) -> ProfileViewModel {
        ProfileViewModel(
            storageService: storageService,
            subscriptionService: subscriptionService,
            authService: authService,
            modelContext: modelContext,
            analyticsService: analyticsService
        )
    }

    func makePaywallViewModel(initialTab: PaywallViewModel.PaywallTab = .points) -> PaywallViewModel {
        PaywallViewModel(subscriptionService: subscriptionService, authService: authService, initialTab: initialTab, analyticsService: analyticsService)
    }
}
