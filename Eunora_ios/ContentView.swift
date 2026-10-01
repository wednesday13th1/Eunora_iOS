import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.45)) { hasCompletedOnboarding = true }
                }
            }
        }
        .tint(EunoiaColor.deepOcean)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [VoyageProfile.self, DailyQuest.self, CheckIn.self, LogEntry.self], inMemory: true)
}
