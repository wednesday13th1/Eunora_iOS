import SwiftUI
import SwiftData

struct VoyageView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var profiles: [VoyageProfile]
    @Query private var allQuests: [DailyQuest]
    @Query private var checkIns: [CheckIn]
    @State private var showCheckIn = false
    @State private var rewardMessage: String?
    @State private var rewardAnchor = false
    @State private var anchorFlying = false
    @State private var oceanSurge = false
    @State private var showBottle = false

    private var today: String { Date.now.eunoiaDayKey }
    private var profile: VoyageProfile? { profiles.first }
    private var quests: [DailyQuest] { allQuests.filter { $0.dayKey == today } }
    private var weather: SeaWeather? { checkIns.first(where: { $0.dayKey == today }).flatMap { SeaWeather(rawValue: $0.weather) } }

    var body: some View {
        ZStack {
            StorybookBackground()
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        ZStack {
                            OceanScene(progress: profile?.distance ?? 0.12, weather: weather) {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                showBottle = true
                            }
                            if oceanSurge {
                                Text("The wind found your sails.").font(.story(20)).foregroundStyle(.white)
                                    .padding(.horizontal, 18).padding(.vertical, 10).background(EunoiaColor.deepOcean.opacity(0.82), in: Capsule())
                                    .transition(.move(edge: .bottom).combined(with: .opacity)).offset(y: 82)
                            }
                        }.id("ocean")
                        voyageStatus
                        if weather == nil { checkInPrompt }
                        questSection
                    }.padding(.horizontal, 18).padding(.bottom, 30)
                }
                .onChange(of: oceanSurge) { _, isSailing in
                    if isSailing { withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) { reader.scrollTo("ocean", anchor: .center) } }
                }
            }
            if rewardAnchor {
                Image(systemName: "anchor.circle.fill").font(.system(size: 64)).foregroundStyle(EunoiaColor.gold)
                    .shadow(color: EunoiaColor.gold.opacity(0.5), radius: 14)
                    .rotationEffect(.degrees(anchorFlying ? 22 : -18))
                    .offset(x: anchorFlying ? 145 : 0, y: anchorFlying ? -315 : 30)
                    .scaleEffect(anchorFlying ? 0.35 : 1)
                    .transition(.scale.combined(with: .opacity)).accessibilityHidden(true)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCheckIn) { CheckInView() }
        .overlay(alignment: .bottom) {
            if let rewardMessage {
                Text(rewardMessage).font(.headline).foregroundStyle(.white).padding(.horizontal, 22).padding(.vertical, 14)
                    .background(EunoiaColor.deepOcean, in: Capsule()).padding(.bottom, 92).transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { seedIfNeeded() }
        .navigationDestination(isPresented: $showBottle) { BottleView() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("Good \(timeOfDay), Sailor.").font(.story(25)).foregroundStyle(EunoiaColor.ink)
                Text("You don’t have to travel far today.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Label("\(profile?.anchors ?? 0)", systemImage: "anchor").font(.headline).foregroundStyle(EunoiaColor.gold).padding(10).background(.white.opacity(0.7), in: Capsule())
        }.padding(.top, 12)
    }

    private var voyageStatus: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAILING TO").font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(.secondary)
                Text(profile?.destination ?? "Kyoto").font(.title3.bold()).foregroundStyle(EunoiaColor.ink)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Today’s distance").font(.caption).foregroundStyle(.secondary)
                Text("\(quests.filter(\.isCompleted).count) gentle steps").font(.subheadline.weight(.semibold)).foregroundStyle(EunoiaColor.deepOcean)
            }
        }
    }

    private var checkInPrompt: some View {
        Button { showCheckIn = true } label: {
            SoftCard { HStack(spacing: 14) {
                Image(systemName: "cloud.sun.fill").font(.title).foregroundStyle(EunoiaColor.gold)
                VStack(alignment: .leading, spacing: 3) { Text("How does the sea feel today?").font(.headline).foregroundStyle(EunoiaColor.ink); Text("A quiet check-in, with no scores.").font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }}
        }.buttonStyle(.plain)
    }

    private var questSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Captain’s Board").font(.story(25)).foregroundStyle(EunoiaColor.ink)
            ForEach(quests) { quest in QuestCard(quest: quest) { complete(quest) } onSkip: { withAnimation { quest.isSkipped = true } } }
        }
    }

    private var bottleCard: some View {
        SoftCard { HStack(spacing: 16) {
            Image(systemName: "waterbottle.fill").font(.largeTitle).foregroundStyle(EunoiaColor.dustyBlue)
            VStack(alignment: .leading) { Text("A bottle is drifting nearby").font(.headline).foregroundStyle(EunoiaColor.ink); Text("There may be a note inside.").font(.subheadline).foregroundStyle(.secondary) }
            Spacer(); Image(systemName: "sparkles").foregroundStyle(EunoiaColor.gold)
        }}
    }

    private func seedIfNeeded() {
        if profiles.isEmpty { context.insert(VoyageProfile(destination: UserDefaults.standard.string(forKey: "selectedDestination") ?? "Kyoto")) }
        if quests.isEmpty {
            [("Take five slow breaths.", "wind"), ("Spend a few minutes somewhere peaceful.", "leaf.fill"), ("Reach out to someone you trust.", "envelope.fill")]
                .forEach { context.insert(DailyQuest(title: $0.0, symbol: $0.1, dayKey: today)) }
        }
    }

    private func complete(_ quest: DailyQuest) {
        guard !quest.isCompleted else { return }
        quest.isCompleted = true; quest.isSkipped = false; profile?.anchors += 1; profile?.distance = min(0.9, (profile?.distance ?? 0.12) + 0.07)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        anchorFlying = false
        withAnimation(reduceMotion ? .easeInOut : .spring(response: 0.55, dampingFraction: 0.5)) { rewardAnchor = true }
        rewardMessage = ["A small step still moves the ship.", "You sailed a little farther today.", "That was enough for now."].randomElement()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.8, dampingFraction: 0.72)) { anchorFlying = true }
            try? await Task.sleep(for: .milliseconds(650)); UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation { rewardAnchor = false; oceanSurge = true }
            try? await Task.sleep(for: .seconds(1.6)); withAnimation { oceanSurge = false; rewardMessage = nil }
        }
    }

    private var timeOfDay: String { let h = Calendar.current.component(.hour, from: .now); return h < 12 ? "morning" : h < 18 ? "afternoon" : "evening" }
}

struct QuestCard: View {
    let quest: DailyQuest; let onComplete: () -> Void; let onSkip: () -> Void
    @State private var stamp = false
    var body: some View {
        ParchmentCard { HStack(spacing: 14) {
            Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : quest.symbol).font(.title2).foregroundStyle(quest.isCompleted ? EunoiaColor.gold : EunoiaColor.deepOcean).frame(width: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text(quest.title).font(.body.weight(.medium)).foregroundStyle(EunoiaColor.ink)
                if !quest.isCompleted && !quest.isSkipped { Button("Not for me today", action: onSkip).font(.caption).foregroundStyle(.secondary) }
                else if quest.isSkipped { Text("Resting here for today — no penalty.").font(.caption).foregroundStyle(.secondary) }
                else { Text("Anchor earned").font(.caption.weight(.semibold)).foregroundStyle(EunoiaColor.gold) }
            }
            Spacer()
            if !quest.isSkipped { Button { withAnimation(.spring(response: 0.28, dampingFraction: 0.48)) { stamp = true }; onComplete() } label: {
                Image(systemName: "anchor.circle.fill").font(.system(size: 38)).foregroundStyle(quest.isCompleted ? EunoiaColor.gold : EunoiaColor.deepOcean.opacity(0.45)).scaleEffect(stamp ? 1 : 0.86)
            }.disabled(quest.isCompleted).accessibilityLabel(quest.isCompleted ? "Completed" : "Stamp quest complete") }
        }}.rotationEffect(.degrees(quest.id.hashValue.isMultiple(of: 2) ? 0.7 : -0.7)).opacity(quest.isSkipped ? 0.62 : 1)
    }
}
