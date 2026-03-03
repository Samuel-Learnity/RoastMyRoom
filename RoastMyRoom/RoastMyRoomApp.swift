import SwiftUI
import SwiftData
import FirebaseCore

@main
struct RoastMyRoomApp: App {
    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            #if DEBUG
            print("[Analytics] GoogleService-Info.plist not found — Firebase disabled, logging to console only")
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .task {
                    for window in UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap(\.windows) {
                        window.backgroundColor = UIColor(named: "BackgroundColor")
                    }
                    #if DEBUG
                    // TODO: Remove — adds 2 free points on each launch for testing
                    AppFactory.shared.subscriptionService.debugAddLaunchPoints()
                    #endif
                }
        }
        .modelContainer(AppFactory.shared.modelContainer)
    }
}
