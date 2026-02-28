import SwiftUI
import SwiftData

@main
struct RoastMyRoomApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(AppFactory.shared.modelContainer)
    }
}
