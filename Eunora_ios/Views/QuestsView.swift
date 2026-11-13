import Combine
import SwiftData
import SwiftUI

struct QuestsView: View {
    var body: some View {
        ScrollView {
            QuestBoard()
                .padding(.vertical, EunoiaSpacing.md)
                .eunoiaReadableContent()
        }
        .background { StorybookBackground() }
        .navigationBarHidden(true)
    }
}

struct QuestBoard: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [VoyageProfile]
    @Query private var records: [DailyQuest]
    @Environment(\.scenePhase) private var scenePhase
    @State private var day = Date.now.eunoiaDayKey
    @State private var categories = WebDailyQuests.categories(on: .now)
    @State private var saveFailed = false
    var onComplete: () -> Void = {}

    var body: some View {
        let currentRecords = records.filter { $0.dayKey == day }
        let recordsByTitle = Dictionary(currentRecords.map { ($0.title, $0) }, uniquingKeysWith: { first, _ in first })
        let titles = Set(categories.flatMap(\.quests).map(\.title))
        let legacyRecords = currentRecords.filter { !titles.contains($0.title) }
        let totalXP = WebDailyQuests.totalXP(for: records)

        LazyVStack(alignment: .leading, spacing: EunoiaSpacing.md) {
            EditorialHeading(text: "Daily Voyage Tasks").accessibilityAddTraits(.isHeader)
            Text("Stamp one small action when it feels right.")
                .foregroundStyle(EunoiaColor.secondaryText)
            Label("\(WebDailyQuests.rank(for: totalXP)) · \(totalXP) XP", systemImage: "sailboat")
                .font(.subheadline)
                .foregroundStyle(EunoiaColor.deepOcean)
                .accessibilityIdentifier("quest-progress")
            ForEach(categories) { category in
                Label {
                    Text(category.title)
                } icon: {
                    Image(systemName: category.symbol)
                        .padding(6)
                        .background(Color(hex: category.accent).opacity(0.25), in: Circle())
                }
                    .font(.headline)
                    .foregroundStyle(EunoiaColor.deepOcean)
                    .accessibilityAddTraits(.isHeader)
                ForEach(category.quests, id: \.id) { quest in
                    if let record = recordsByTitle[quest.title] {
                        card(record)
                    }
                }
            }
            if !legacyRecords.isEmpty {
                Text("Earlier today").font(.headline).accessibilityAddTraits(.isHeader)
                ForEach(legacyRecords) { card($0) }
            }
            Text("Unfinished notes simply drift away tonight. There is nothing to catch up on.")
                .font(.footnote)
                .foregroundStyle(EunoiaColor.secondaryText)
        }
        .alert("Progress couldn’t be saved", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can try again when you’re ready.")
        }
        .task { refreshDay() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in refreshDay() }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in refreshDay() }
    }

    private func refreshDay() {
        let now = Date.now
        let key = now.eunoiaDayKey
        if key != day {
            day = key
            categories = WebDailyQuests.categories(on: now)
        }
        seed(day: key)
    }

    private func card(_ quest: DailyQuest) -> some View {
        QuestCard(quest: quest) {
            guard !quest.isCompleted else { return }
            let profile = profiles.first
            let previousDistance = profile?.distance
            let wasSkipped = quest.isSkipped
            quest.isCompleted = true
            quest.isSkipped = false
            profile?.anchors += 1
            profile?.distance = min(0.9, (previousDistance ?? 0.12) + 0.07)
            do {
                try context.save()
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                onComplete()
            } catch {
                quest.isCompleted = false
                quest.isSkipped = wasSkipped
                profile?.anchors -= 1
                if let previousDistance { profile?.distance = previousDistance }
                saveFailed = true
            }
        } onSkip: {
            quest.isSkipped = true
        }
    }

    private func seed(day: String) {
        let descriptor = FetchDescriptor<DailyQuest>(predicate: #Predicate { $0.dayKey == day })
        guard let existing = try? context.fetch(descriptor),
              let existingProfiles = try? context.fetch(FetchDescriptor<VoyageProfile>()) else { return }
        if existingProfiles.isEmpty {
            context.insert(VoyageProfile(destination: UserDefaults.standard.string(forKey: "selectedDestination") ?? "Kyoto"))
        }
        let existingTitles = Set(existing.map(\.title))
        for category in categories {
            for quest in category.quests where !existingTitles.contains(quest.title) {
                context.insert(DailyQuest(title: quest.title, symbol: category.symbol, dayKey: day))
            }
        }
    }
}


#Preview("Accessible quest board") {
    QuestsView()
        .environment(\.dynamicTypeSize, .accessibility3)
        .modelContainer(for: [VoyageProfile.self, DailyQuest.self], inMemory: true)
}
