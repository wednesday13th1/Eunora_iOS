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
    @State private var date = Date.now
    @State private var saveFailed = false
    var onComplete: () -> Void = {}

    private var categories: [WebDailyQuests.Category] { WebDailyQuests.categories(on: date) }
    private var today: String { date.eunoiaDayKey }
    private var currentRecords: [DailyQuest] { records.filter { $0.dayKey == today } }
    private var totalXP: Int {
        records.filter(\.isCompleted).reduce(0) { $0 + (WebDailyQuests.xpByTitle[$1.title] ?? 0) }
    }
    private var legacyRecords: [DailyQuest] {
        let currentTitles = Set(categories.flatMap(\.quests).map(\.title))
        return currentRecords.filter { !currentTitles.contains($0.title) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EunoiaSpacing.md) {
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
                    if let record = currentRecords.first(where: { $0.title == quest.title }) {
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
        .task {
            while !Task.isCancelled {
                date = .now
                seed()
                do { try await Task.sleep(for: .seconds(30)) }
                catch { return }
            }
        }
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

    private func seed() {
        let day = today
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
