import SwiftUI
import SwiftData

@main
struct RoastMyRoomApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppFactory.shared.modelContainer)
    }
}
