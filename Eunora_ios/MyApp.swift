import SwiftUI
import SwiftData

@main struct MyApp: App {
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-welcome-for-ui-test") {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [VoyageProfile.self, DailyQuest.self, CheckIn.self, LogEntry.self])
    }
}
