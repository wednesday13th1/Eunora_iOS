import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootTabView()
            } else {
                OnboardingView {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) { hasCompletedOnboarding = true }
                }
            }
        }
        .font(.voyageBody())
        .tint(EunoiaColor.deepOcean)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [VoyageProfile.self, DailyQuest.self, CheckIn.self, LogEntry.self], inMemory: true)
}
