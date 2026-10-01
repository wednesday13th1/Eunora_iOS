import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [VoyageProfile.self, DailyQuest.self, CheckIn.self, LogEntry.self])
    }
}
